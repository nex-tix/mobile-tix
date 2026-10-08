import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The app's text field.
///
/// The label sits *above* the field as a tracked data label rather than floating
/// inside it: at a gate the label has to stay readable while the field is filled,
/// and the floating variant makes the operator hunt for it. Filled with the sunken
/// paper tone so a field is findable on the ground without a heavy outline.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.labelTrailing,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.style,
    this.maxLength,
    this.autofillHints,
  });

  final String? label;
  final Widget? labelTrailing;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final TextStyle? style;
  final int? maxLength;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Expanded(child: Text(label!.toUpperCase(), style: text.label)),
              ?labelTrailing,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          maxLength: maxLength,
          enableSuggestions: !obscure,
          autocorrect: false,
          cursorColor: c.primary,
          cursorRadius: const Radius.circular(1),
          cursorWidth: 2,
          style: style ?? text.body.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: c.inkMuted),
            prefixIconConstraints: const BoxConstraints(
              minWidth: AppSpacing.xxl + AppSpacing.xxs,
              minHeight: AppSpacing.touchTarget,
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: AppSpacing.touchTarget,
              minHeight: AppSpacing.touchTarget,
            ),
          ),
        ),
      ],
    );
  }
}
