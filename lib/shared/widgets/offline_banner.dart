import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Full-bleed offline notice.
///
/// The gate must not hide the scanner when the network drops, so this sits *under*
/// the header as a 52px band rather than replacing the screen: the operator can see
/// the network is out, see the scanner, and see that the scan action is disabled —
/// all in one glance, without a dialog they would dismiss.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.title = 'Anda sedang offline',
    this.detail = 'Pindai dinonaktifkan sampai koneksi kembali.',
    this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.secondaryTint,
        border: Border(
          bottom: BorderSide(color: c.secondary.withValues(alpha: 0.45)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xs + 2,
        AppSpacing.sm,
        AppSpacing.xs + 2,
      ),
      child: Row(
        children: [
          Icon(AppIcons.wifiOff, size: 18, color: c.onSecondaryTint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.bodyStrong.copyWith(
                    color: c.onSecondaryTint,
                    fontSize: 14,
                  ),
                ),
                Text(
                  detail,
                  style: text.supporting.copyWith(
                    color: c.onSecondaryTint.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                // The recovery action is the strongest thing on the band: ink on the
                // mustard tint (11.6:1), not gold on gold.
                foregroundColor: c.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(
                  AppSpacing.touchTarget,
                  AppSpacing.touchTarget,
                ),
              ),
              child: const Text('COBA'),
            ),
        ],
      ),
    );
  }
}
