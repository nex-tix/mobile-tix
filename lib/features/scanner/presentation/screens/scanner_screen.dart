import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/ticket_status.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../auth/logic/session_state.dart';
import '../../../../shared/widgets/inline_status.dart';
import '../../bloc/scanner_cubit.dart';
import '../../bloc/scanner_state.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/scanner_viewfinder.dart';

/// Screen 5: Scan Check-In matching `newDesign/5._scan_check_in/code.html`.
///
/// Layar ini tidak memvalidasi tiket sendiri: ia menyerahkan kode ke
/// [ScannerCubit] dan hanya menampilkan apa yang cubit laporkan — hasil dari
/// server, masuk antrean karena offline, atau gagal.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _showManualInput = false;

  // Walkthrough sample codes
  static const List<String> _sampleCodes = [
    'TKT-2026-001245', // Valid
    'TKT-2026-001244', // Re-use / Already used
    'TKT-2026-001243', // Expired
    'TKT-2026-001242', // Cancelled
    'TKT-2026-001241', // Not found
  ];
  int _sampleIndex = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Kirim satu kode ke cubit.
  Future<void> _submit(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.warning(
        context,
        context.trSafe('scanner.codeRequired', 'Masukkan kode tiket'),
      );
      return;
    }

    final checkpointId = context.read<SessionState>().checkpoint?.id ?? '';
    if (checkpointId.isEmpty) {
      AppSnackbar.warning(
        context,
        context.trSafe('auth.gateRequired', 'Checkpoint aktif belum dipilih'),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _codeController.clear();
    if (_showManualInput) setState(() => _showManualInput = false);

    await context.read<ScannerCubit>().scanTicket(
      ticketCode: trimmed,
      checkpointId: checkpointId,
    );
  }

  void _simulateCameraScan() {
    final code = _sampleCodes[_sampleIndex % _sampleCodes.length];
    _sampleIndex++;
    _submit(code);
  }

  /// Reaksi terhadap hasil yang tidak lagi menunggu.
  Future<void> _onScanOutcome(ScannerState state) async {
    final cubit = context.read<ScannerCubit>();

    switch (state) {
      case ScannerSuccess(result: final result):
        if (result.status == TicketStatus.valid) {
          AudioFeedbackService.instance.playSuccess();
        } else {
          AudioFeedbackService.instance.playError();
        }
        final gate = context.read<SessionState>().checkpoint?.gate;
        await ScanResultSheet.show(
          context,
          outcome: result.toOutcome(gate: gate),
          autoDismiss:
              result.status == TicketStatus.valid &&
              result.mode == ScanMode.checkIn,
          onRetry: () => _submit(result.ticketCode),
        );
        if (!mounted) return;
        cubit.acknowledgeResult();

      case ScannerQueued(ticketCode: final code):
        AudioFeedbackService.instance.playError();
        AppSnackbar.warning(
          context,
          context.trSafe(
            'scanner.offlineQueued',
            'Offline — {code} masuk antrean dan akan dikirim otomatis saat koneksi pulih.',
            namedArgs: {'code': code},
          ),
          duration: const Duration(seconds: 4),
        );
        cubit.acknowledgeResult();

      case ScannerError(message: final message):
        AudioFeedbackService.instance.playError();
        AppSnackbar.danger(context, message);
        cubit.acknowledgeResult();

      case ScannerIdle():
      case ScannerProcessing():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final connectivity = context.watch<DemoConnectivity>();
    final checkpoint = session.checkpoint;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewHeight = (screenHeight * 0.44).clamp(240.0, 380.0);

    return Scaffold(
      backgroundColor: context.colors.ground,
      body: BlocListener<ScannerCubit, ScannerState>(
        listenWhen: (previous, current) =>
            current is ScannerSuccess ||
            current is ScannerQueued ||
            current is ScannerError,
        listener: (context, state) => _onScanOutcome(state),
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<ScannerCubit, ScannerState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      gate: checkpoint?.gate ?? 'Gate 1',
                      online: connectivity.online,
                      isChecking: connectivity.isChecking,
                      onRefresh: () async {
                        final ok = await context
                            .read<DemoConnectivity>()
                            .checkConnection();
                        if (context.mounted) {
                          if (ok) {
                            AppSnackbar.success(
                              context,
                              context.trSafe(
                                'connectivity.connectedSuccess',
                                'Sinyal terhubung kembali (Online)',
                              ),
                            );
                          } else {
                            AppSnackbar.warning(
                              context,
                              context.trSafe(
                                'connectivity.stillOffline',
                                'Sinyal belum ditemukan, masih Mode Offline',
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    if (state.hasPendingSync) ...[
                      _PendingBanner(count: state.pendingSync),
                      const SizedBox(height: 12),
                    ],

                    _ModeSwitch(
                      mode: state.mode,
                      onChanged: (mode) =>
                          context.read<ScannerCubit>().setMode(mode),
                    ),
                    const SizedBox(height: 14),

                    ScannerViewfinder(
                      height: viewHeight,
                      onSimulate: _simulateCameraScan,
                      onScanned: _submit,
                      processing: state.isProcessing,
                      disabled: false,
                    ),
                    const SizedBox(height: 14),

                    _manualInputSection(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _manualInputSection() {
    if (!_showManualInput) {
      return SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: context.colors.surface,
            side: BorderSide(color: context.colors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => setState(() => _showManualInput = true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.keyboard, size: 18, color: context.colors.inkMuted),
              const SizedBox(width: 8),
              Text(
                context.trSafe('scanner.enterCode', 'Enter code manually'),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              autofocus: true,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14.5,
                color: context.colors.ink,
              ),
              decoration: InputDecoration(
                hintText: context.trSafe(
                  'scanner.codeHint',
                  'e.g. TKT-2026-001245',
                ),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: context.colors.inkMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onSubmitted: _submit,
            ),
          ),
          IconButton(
            icon: Icon(AppIcons.arrowForward, color: context.colors.inkMuted),
            onPressed: () => _submit(_codeController.text),
          ),
          IconButton(
            icon: Icon(
              AppIcons.close,
              color: context.colors.inkMuted,
              size: 18,
            ),
            onPressed: () => setState(() => _showManualInput = false),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.gate,
    required this.online,
    this.isChecking = false,
    this.onRefresh,
  });

  final String gate;
  final bool online;
  final bool isChecking;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.trSafe('scanner.title', 'Scan Ticket'),
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              gate,
              style: TextStyle(
                fontSize: 12.5,
                color: context.colors.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        ConnectionPill(
          online: online,
          isChecking: isChecking,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

/// Berapa tiket tertahan karena koneksi putus.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.secondaryTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colors.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(AppIcons.wifiOff, size: 18, color: context.colors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.trSafe(
                'scanner.pendingSync',
                '$count tiket menunggu dikirim ke server',
                namedArgs: {'count': '$count'},
              ),
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.colors.onSecondaryTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CHECK-IN | CEK — dua pekerjaan pemindai.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          for (final option in ScanMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: mode == option ? context.colors.primary : null,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    option == ScanMode.checkIn
                        ? context.trSafe('scanner.checkIn', 'Check-in')
                        : context.trSafe('scanner.check', 'Check'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: mode == option
                          ? context.colors.onPrimary
                          : context.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
