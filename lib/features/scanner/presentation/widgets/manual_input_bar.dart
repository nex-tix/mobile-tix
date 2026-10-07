import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/scan_outcome.dart';

/// The Keyboard path: a torn QR or a refused camera must never stop the gate, so the
/// code can always be keyed in. The action button carries the mode's own word, so the
/// operator can see *what pressing it will do* without reading the switch above.
class ManualInputBar extends StatelessWidget {
  const ManualInputBar({
    super.key,
    required this.controller,
    required this.mode,
    required this.onSubmit,
    required this.enabled,
    this.processing = false,
    this.errorText,
  });

  final TextEditingController controller;
  final ScanMode mode;
  final ValueChanged<String> onSubmit;
  final bool enabled;
  final bool processing;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final field = AppTextField(
          label: 'Input manual',
          hint: 'TKT-2026-001245',
          controller: controller,
          enabled: enabled,
          prefixIcon: Icons.keyboard_alt_outlined,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          keyboardType: TextInputType.text,
          style: text.code,
          errorText: errorText,
          onSubmitted: onSubmit,
        );

        final button = AppButton(
          label: mode.label,
          icon: Icons.qr_code_scanner_rounded,
          loading: processing,
          expanded: false,
          onPressed: enabled && !processing
              ? () => onSubmit(controller.text)
              : null,
        );

        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: mode.label,
                icon: Icons.qr_code_scanner_rounded,
                loading: processing,
                onPressed: enabled && !processing
                    ? () => onSubmit(controller.text)
                    : null,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: field),
            const SizedBox(width: AppSpacing.sm),
            button,
          ],
        );
      },
    );
  }
}
