import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A decision that must interrupt: leaving the shift, changing the gate.
///
/// Only used where the action is genuinely destructive or irreversible — the app has
/// no confirm-everything reflex.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'KELUAR',
  String cancelLabel = 'BATAL',
  bool destructive = true,
}) async {
  final c = context.colors;
  final text = AppText.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      title: Text(title, style: text.sheetTitle),
      content: Text(message, style: text.supporting.copyWith(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(foregroundColor: c.inkMuted),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? c.used : c.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
