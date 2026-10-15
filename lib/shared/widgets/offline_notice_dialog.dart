import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../core/connectivity/demo_connectivity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/widgets/app_snackbar.dart';
import '../../core/utils/i18n_helper.dart';

/// Dialog notifikasi di tengah layar saat sinyal hilang / offline
class OfflineNoticeDialog extends StatefulWidget {
  const OfflineNoticeDialog({
    super.key,
    required this.connectivity,
    this.onDismiss,
  });

  final DemoConnectivity connectivity;
  final VoidCallback? onDismiss;

  @override
  State<OfflineNoticeDialog> createState() => _OfflineNoticeDialogState();
}

class _OfflineNoticeDialogState extends State<OfflineNoticeDialog> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _checkSignal() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    final isOnline = await widget.connectivity.checkConnection();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isOnline) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      } else {
        Navigator.of(context, rootNavigator: true).pop();
      }
      AppSnackbar.success(
        context,
        context.trSafe(
          'connectivity.connectedSuccess',
          'Sinyal terhubung kembali (Online)',
        ),
      );
    } else {
      setState(() {
        _statusMessage = context.trSafe(
          'connectivity.stillOffline',
          'Tidak ada sinyal',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.outline, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Offline
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.wifiOff,
                    size: 28,
                    color: c.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                context.trSafe('connectivity.offlineTitle', 'Mode Offline'),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Status Subtitle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  context.trSafe('connectivity.noSignal', 'Tidak Ada Sinyal'),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              // Action Button 1: Cari Sinyal / Refresh
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isChecking ? null : _checkSignal,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(AppIcons.refresh, size: 18),
                  label: Text(
                    _isChecking
                        ? context.trSafe(
                            'connectivity.searchingSignal',
                            'Mencari sinyal...',
                          )
                        : context.trSafe(
                            'connectivity.searchSignal',
                            'Cari Sinyal',
                          ),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Action Button 2: Lanjut Scan Offline
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: c.inkMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (widget.onDismiss != null) {
                      widget.onDismiss!();
                    } else {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  child: Text(
                    context.trSafe(
                      'connectivity.continueOffline',
                      'Lanjut Scan Offline',
                    ),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
