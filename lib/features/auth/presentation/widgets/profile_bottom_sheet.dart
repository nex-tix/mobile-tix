import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../logic/session_state.dart';

/// Profile Bottom Sheet based on `newDesign/15._profile_bottom_sheet/code.html`.
class ProfileBottomSheet extends StatelessWidget {
  const ProfileBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final connectivity = context.watch<DemoConnectivity>();
    final staff = session.staff;
    final checkpoint = session.checkpoint;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: context.colors.outline, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Grabber Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: context.colors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Officer Profile Header Info
            Row(
              children: [
                // Avatar with Subtle Ring
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.surfaceAlt,
                    border: Border.all(color: context.colors.outline, width: 2),
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Text(
                        staff?.initials ?? 'R',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5D061),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Officer Name & Handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        staff?.name ?? 'Raya',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff?.role ?? context.tr('profile.defaultRole'),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Settings List
            Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.colors.outline),
              ),
              child: Column(
                children: [
                  // Checkpoint Display Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.meetingRoom, size: 20, color: context.colors.inkMuted),
                            const SizedBox(width: 12),
                            Text(
                              context.tr('profile.checkpoint'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: context.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          checkpoint?.gate ?? 'Gate 1',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: context.colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: context.colors.outline),

                  // Connection Status Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.wifi, size: 20, color: context.colors.inkMuted),
                            const SizedBox(width: 12),
                            Text(
                              context.tr('profile.connection'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: context.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: connectivity.online
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFCF4647),
                              ),
                            ),
                            Text(
                              connectivity.online
                                  ? context.tr('common.online')
                                  : context.tr('common.offline'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: connectivity.online
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFCF4647),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout Action Button
            SizedBox(
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.colors.surface,
                  side: BorderSide(color: context.colors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: context.tr('auth.logoutTitle'),
                    message: context.tr('auth.logoutMessage'),
                    confirmLabel: context.tr('common.logout'),
                  );
                  if (!ok || !context.mounted) return;
                  Navigator.of(context).pop();
                  context.read<SessionState>().signOut();
                  context.read<AuthBloc>().add(const LogoutRequested());
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.logout, size: 18, color: Color(0xFFCF4647)),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('common.logout'),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCF4647),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
