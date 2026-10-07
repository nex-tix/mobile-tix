import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
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
      decoration: const BoxDecoration(
        color: Color(0xFF212B2F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: Color(0xFF3E4E55), width: 1.2),
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
                  color: const Color(0xFF4B5E66),
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
                    color: const Color(0xFF1E272B),
                    border: Border.all(color: const Color(0xFF334147), width: 2),
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
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF8F6F6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff?.employeeId.isNotEmpty == true
                            ? staff!.employeeId.toLowerCase()
                            : 'raya23',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA3B1B7),
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
                color: const Color(0xFF1E272B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF334147)),
              ),
              child: Column(
                children: [
                  // Checkpoint Display Row (tidak bisa diklik)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(AppIcons.meetingRoom, size: 20, color: Color(0xFFA3B1B7)),
                            SizedBox(width: 12),
                            Text(
                              'Checkpoint',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFFA3B1B7),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          checkpoint?.gate ?? 'Gate 1',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF8F6F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFF334147)),

                  // Connection Status Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(AppIcons.wifi, size: 20, color: Color(0xFFA3B1B7)),
                            SizedBox(width: 12),
                            Text(
                              'Connection',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFFA3B1B7),
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
                              connectivity.online ? 'Online' : 'Offline',
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
                  backgroundColor: const Color(0xFF212B2F),
                  side: const BorderSide(color: Color(0xFF3E4E55)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Keluar dari akun?',
                    message: 'Sesi saat ini akan diakhiri.',
                    confirmLabel: 'LOGOUT',
                  );
                  if (ok && context.mounted) {
                    Navigator.of(context).pop();
                    context.read<SessionState>().signOut();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(AppIcons.logout, size: 18, color: Color(0xFFCF4647)),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
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
