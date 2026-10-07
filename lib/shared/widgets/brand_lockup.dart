import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The brand lockup: the supplied logo, held at its own aspect ratio on a paper
/// plate, with the product wordmark beside it.
///
/// The logo is a bold mark with hand-painted edges, so it is never blown up to
/// illustration size (the brief rules that out anyway) and never re-coloured: it sits
/// in a fixed square plate and is fitted inside it, which keeps the ratio intact.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.plateSize = 72,
    this.showWordmark = true,
    this.alignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.start,
  });

  final double plateSize;
  final bool showWordmark;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    final plate = Container(
      width: plateSize,
      height: plateSize,
      padding: EdgeInsets.all(plateSize * 0.08),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(plateSize * 0.25),
        border: Border.all(color: c.outline),
      ),
      child: Image.asset(
        AppConfig.logoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: AppConfig.appName,
      ),
    );

    if (!showWordmark) return plate;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        plate,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: alignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConfig.productWordmark,
                textAlign: textAlign,
                style: text.sheetTitle.copyWith(letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(
                AppConfig.appName,
                textAlign: textAlign,
                style: text.supporting.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
