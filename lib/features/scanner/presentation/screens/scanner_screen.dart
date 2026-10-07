import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/ticket_status.dart';
import '../../../auth/logic/session_state.dart';
import '../../data/models/scan_outcome.dart';
import '../../logic/scanner_state.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/scanner_viewfinder.dart';

/// Screen 5: Scan Check-In matching `newDesign/5._scan_check_in/code.html`.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _showManualInput = false;
  String? _codeError;

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

  Future<void> _run(String code) async {
    final session = context.read<SessionState>();
    final connectivity = context.read<DemoConnectivity>();
    final scanner = context.read<ScannerState>();

    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      setState(() => _codeError = 'Masukkan kode tiket');
      return;
    }
    if (connectivity.offline) {
      setState(() => _codeError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pindai dinonaktifkan saat offline.')),
      );
      return;
    }

    setState(() => _codeError = null);
    FocusScope.of(context).unfocus();
    final outcome = await scanner.scan(
      code: trimmed,
      gate: session.checkpoint?.gate,
    );
    if (!mounted) return;
    _codeController.clear();
    setState(() => _showManualInput = false);

    await ScanResultSheet.show(
      context,
      outcome: outcome,
      autoDismiss: outcome.status == TicketStatus.valid,
      onRetry: () => _run(trimmed),
    );
  }

  void _simulateCameraScan() {
    final code = _sampleCodes[_sampleIndex % _sampleCodes.length];
    _sampleIndex++;
    _run(code);
  }

  void _pickStatus(TicketStatus status) {
    final scanner = context.read<ScannerState>();
    final outcome = scanner.showStatus(status);
    ScanResultSheet.show(context, outcome: outcome, autoDismiss: false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final connectivity = context.watch<DemoConnectivity>();
    final scanner = context.watch<ScannerState>();
    final checkpoint = session.checkpoint;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewHeight = (screenHeight * 0.44).clamp(240.0, 380.0);

    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Bar: "Scan Ticket" & Online Status
              Row(
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
                        checkpoint?.gate ?? 'Gate 1',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFA3B1B7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Online Badge (tappable to simulate offline)
                  GestureDetector(
                    onTap: () => context.read<DemoConnectivity>().toggle(),
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
                              color: connectivity.online
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFCF4647),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connectivity.online ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: connectivity.online
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFCF4647),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Mode Switch: Check-in vs Check
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E272B),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFF334147)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (scanner.mode != ScanMode.checkIn) {
                            scanner.setMode(ScanMode.checkIn);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: scanner.mode == ScanMode.checkIn
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFCF4647),
                                      Color(0xFFB83A3B),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Check-in',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: scanner.mode == ScanMode.checkIn
                                  ? const Color(0xFFF8F6F6)
                                  : const Color(0xFFA3B1B7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (scanner.mode != ScanMode.check) {
                            scanner.setMode(ScanMode.check);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: scanner.mode == ScanMode.check
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFCF4647),
                                      Color(0xFFB83A3B),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Check',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: scanner.mode == ScanMode.check
                                  ? const Color(0xFFF8F6F6)
                                  : const Color(0xFFA3B1B7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Camera Viewfinder Area
              ScannerViewfinder(
                height: viewHeight,
                onSimulate: _simulateCameraScan,
                processing: scanner.processing,
                disabled: connectivity.offline,
              ),
              const SizedBox(height: 14),

              // Manual Code Entry Action Button
              if (!_showManualInput)
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF212B2F),
                      side: const BorderSide(color: Color(0xFF3E4E55)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _showManualInput = true);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          AppIcons.keyboard,
                          size: 18,
                          color: Color(0xFFA3B1B7),
                        ),
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
                )
              else
                // Inline Manual Code Input
                Container(
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
                          decoration: InputDecoration(
                            hintText: 'e.g. TKT-2026-001245',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFA3B1B7),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            errorText: _codeError,
                          ),
                          onSubmitted: _run,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.arrowForward, color: Color(0xFFF5D061)),
                        onPressed: () => _run(_codeController.text),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.close, color: Color(0xFFA3B1B7), size: 18),
                        onPressed: () => setState(() => _showManualInput = false),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // Demo Walkthrough Quick Trigger Pills
              Container(
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
                        _demoChip(
                          label: 'Valid',
                          color: const Color(0xFF2ECC71),
                          onTap: () => _pickStatus(TicketStatus.valid),
                        ),
                        _demoChip(
                          label: 'Already Used',
                          color: const Color(0xFFCF4647),
                          onTap: () => _pickStatus(TicketStatus.alreadyUsed),
                        ),
                        _demoChip(
                          label: 'Expired',
                          color: const Color(0xFFF5D061),
                          onTap: () => _pickStatus(TicketStatus.expired),
                        ),
                        _demoChip(
                          label: 'Invalid',
                          color: const Color(0xFFA3B1B7),
                          onTap: () => _pickStatus(TicketStatus.notFound),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoChip({
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
