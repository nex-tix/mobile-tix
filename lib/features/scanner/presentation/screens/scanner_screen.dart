import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/ticket_status.dart';
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../auth/logic/session_state.dart';
import '../../bloc/scanner_cubit.dart';
import '../../bloc/scanner_state.dart';
import '../../data/dummy_scans.dart';
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

  /// Kirim satu kode ke cubit. Validasi yang bisa dilakukan tanpa jaringan
  /// (kode kosong, gate belum dipilih) ditangani di sini supaya tidak menjadi
  /// permintaan yang pasti gagal.
  Future<void> _submit(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.warning(context, 'Masukkan kode tiket');
      return;
    }

    final checkpointId =
        context.read<SessionState>().checkpoint?.id ?? '';
    if (checkpointId.isEmpty) {
      AppSnackbar.warning(context, 'Checkpoint aktif belum dipilih');
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

  /// Tombol pratinjau: memaksa satu verdict supaya kelima tampilan hasil bisa
  /// diperiksa tanpa backend. Datanya dibuat lokal dan tidak pernah dikirim.
  void _pickStatus(TicketStatus status) {
    final mode = context.read<ScannerCubit>().state.mode;
    final outcome = DummyScanner.demo(status, mode);
    ScanResultSheet.show(context, outcome: outcome, autoDismiss: false);
  }

  /// Reaksi terhadap hasil yang tidak lagi menunggu: tutup verdict, atau
  /// beritahukan apa yang terjadi pada tiket yang tidak bisa diproses.
  Future<void> _onScanOutcome(ScannerState state) async {
    final cubit = context.read<ScannerCubit>();

    switch (state) {
      case ScannerSuccess(result: final result):
        final gate = context.read<SessionState>().checkpoint?.gate;
        await ScanResultSheet.show(
          context,
          outcome: result.toOutcome(gate: gate),
          // Hanya check-in yang sah yang menutup sendiri: petugas tidak perlu
          // menekan apa pun saat tiket lolos, tapi setiap penolakan harus
          // bertahan sampai dibaca.
          autoDismiss:
              result.status == TicketStatus.valid &&
              result.mode == ScanMode.checkIn,
          onRetry: () => _submit(result.ticketCode),
        );
        if (!mounted) return;
        cubit.acknowledgeResult();

      case ScannerQueued(ticketCode: final code):
        AppSnackbar.warning(
          context,
          'Offline — $code masuk antrean dan akan dikirim otomatis saat koneksi pulih.',
          duration: const Duration(seconds: 4),
        );
        cubit.acknowledgeResult();

      case ScannerError(message: final message):
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
      backgroundColor: const Color(0xFF2A363B),
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
                      onToggleConnectivity: () =>
                          context.read<DemoConnectivity>().toggle(),
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
                      processing: state.isProcessing,
                      // Offline tidak lagi mematikan pemindai: scan disimpan ke
                      // antrean dan dikirim saat koneksi pulih.
                      disabled: false,
                    ),
                    const SizedBox(height: 14),

                    _manualInputSection(),
                    const SizedBox(height: 18),
                    _DemoOutcomes(onPick: _pickStatus),
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
            backgroundColor: const Color(0xFF212B2F),
            side: const BorderSide(color: Color(0xFF3E4E55)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => setState(() => _showManualInput = true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(AppIcons.keyboard, size: 18, color: Color(0xFFA3B1B7)),
              SizedBox(width: 8),
              Text(
                'Enter code manually',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8F6F6),
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
        color: const Color(0xFF212B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3E4E55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              autofocus: true,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14.5,
                color: Color(0xFFF8F6F6),
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. TKT-2026-001245',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFFA3B1B7)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              onSubmitted: _submit,
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.arrowForward, color: Color(0xFFF5D061)),
            onPressed: () => _submit(_codeController.text),
          ),
          IconButton(
            icon: const Icon(
              AppIcons.close,
              color: Color(0xFFA3B1B7),
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
    required this.onToggleConnectivity,
  });

  final String gate;
  final bool online;
  final VoidCallback onToggleConnectivity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan Ticket',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF8F6F6),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              gate,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFA3B1B7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onToggleConnectivity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x3310B981),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0x6610B981)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCF4647),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: online
                        ? const Color(0xFF34D399)
                        : const Color(0xFFCF4647),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Berapa tiket tertahan karena koneksi putus.
///
/// Ditampilkan menonjol karena ini satu-satunya cara petugas tahu ada check-in
/// yang belum sampai ke server.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x33F5D061),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66F5D061)),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.wifiOff, size: 18, color: Color(0xFFF5D061)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count tiket menunggu dikirim ke server',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF5D061),
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
        color: const Color(0xFF1E272B),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF334147)),
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
                    gradient: mode == option
                        ? const LinearGradient(
                            colors: [Color(0xFFCF4647), Color(0xFFB83A3B)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    option == ScanMode.checkIn ? 'Check-in' : 'Check',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: mode == option
                          ? const Color(0xFFF8F6F6)
                          : const Color(0xFFA3B1B7),
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

/// Pratinjau kelima verdict + mode cek, jelas ditandai sebagai simulasi.
class _DemoOutcomes extends StatelessWidget {
  const _DemoOutcomes({required this.onPick});

  final ValueChanged<TicketStatus> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334147)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'DEMO OUTCOMES (SIMULASI)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFFA3B1B7),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(
                label: 'Valid',
                color: const Color(0xFF2ECC71),
                onTap: () => onPick(TicketStatus.valid),
              ),
              _chip(
                label: 'Already Used',
                color: const Color(0xFFCF4647),
                onTap: () => onPick(TicketStatus.alreadyUsed),
              ),
              _chip(
                label: 'Expired',
                color: const Color(0xFFF5D061),
                onTap: () => onPick(TicketStatus.expired),
              ),
              _chip(
                label: 'Invalid',
                color: const Color(0xFFA3B1B7),
                onTap: () => onPick(TicketStatus.notFound),
              ),
              _chip(
                label: 'Cancelled',
                color: const Color(0xFFCF4647),
                onTap: () => onPick(TicketStatus.cancelled),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
