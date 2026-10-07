import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../logic/session_state.dart';

/// Full-screen profile screen conforming to `newDesign/15._profile_bottom_sheet/code.html`.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final connectivity = context.watch<DemoConnectivity>();
    final staff = session.staff;
    final checkpoint = session.checkpoint;

    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profil Petugas',
          style: TextStyle(
            fontFamily: 'Barlow',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFFF8F6F6),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Officer Profile Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF212B2F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF3E4E55)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff?.name ?? 'Raya',
                            style: const TextStyle(
                              fontFamily: 'Barlow',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF8F6F6),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            staff?.role ?? 'Gate Staff · Shift Utama',
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
              ),
              const SizedBox(height: 20),

              // Operational details card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF212B2F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3E4E55)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.meeting_room_outlined, size: 20, color: Color(0xFFA3B1B7)),
                              SizedBox(width: 12),
                              Text(
                                'Checkpoint',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFA3B1B7),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            checkpoint?.gate ?? 'Gate 1',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF8F6F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFF334147)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.wifi_rounded, size: 20, color: Color(0xFFA3B1B7)),
                              SizedBox(width: 12),
                              Text(
                                'Koneksi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFA3B1B7),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
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
                                  fontSize: 13.5,
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
              const SizedBox(height: 28),

              // Logout Button
              SizedBox(
                height: 52,
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
                      context.read<SessionState>().signOut();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, size: 18, color: Color(0xFFCF4647)),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontFamily: 'Barlow',
                          fontSize: 15,
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
      ),
    );
  }
}
