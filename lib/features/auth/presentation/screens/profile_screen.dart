import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_tix/core/bloc/auth/auth_bloc.dart';
import 'package:mobile_tix/core/bloc/auth/auth_event.dart';
import 'package:mobile_tix/core/bloc/language/language_cubit.dart';
import 'package:mobile_tix/core/bloc/theme/theme_cubit.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        title: Text(
          context.tr('profile.title'),
          style: const TextStyle(
            fontFamily: 'DMSans',
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
                              fontFamily: 'DMSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF8F6F6),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            staff?.role ?? context.tr('profile.defaultRole'),
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

                            // Settings Card: Theme & Language
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF212B2F),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF3E4E55)),
                              ),
                              child: Column(
                                children: [
                                  // Theme Row
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    leading: Icon(AppIcons.sun, size: 22, color: const Color(0xFFA3B1B7)),
                                    title: Text(
                                      context.tr('profile.theme'),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFFA3B1B7)),
                                    ),
                                    trailing: BlocBuilder<ThemeCubit, ThemeMode>(
                                      builder: (context, themeMode) {
                                        final String label;
                                        switch (themeMode) {
                                          case ThemeMode.light:
                                            label = context.tr('common.light');
                                            break;
                                          case ThemeMode.dark:
                                            label = context.tr('common.dark');
                                            break;
                                          case ThemeMode.system:
                                            label = context.tr('common.system');
                                            break;
                                        }
                                        return Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFF8F6F6),
                                          ),
                                        );
                                      },
                                    ),
                                    onTap: () async {
                                      final cubit = context.read<ThemeCubit>();
                                      if (cubit.state == ThemeMode.light) {
                                        await cubit.setThemeMode(ThemeMode.dark);
                                      } else if (cubit.state == ThemeMode.dark) {
                                        await cubit.setThemeMode(ThemeMode.system);
                                      } else {
                                        await cubit.setThemeMode(ThemeMode.light);
                                      }
                                    },
                                  ),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFF334147)),

                                  // Language Row
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    leading: Icon(AppIcons.language, size: 22, color: const Color(0xFFA3B1B7)),
                                    title: Text(
                                      context.tr('profile.language'),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFFA3B1B7)),
                                    ),
                                    trailing: BlocBuilder<LanguageCubit, Locale>(
                                      builder: (context, state) {
                                        return Text(
                                          state.languageCode == 'en'
                                              ? context.tr('common.english')
                                              : context.tr('common.indonesian'),
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFF8F6F6),
                                          ),
                                        );
                                      },
                                    ),
                                    onTap: () async {
                                      final cubit = context.read<LanguageCubit>();
                                      if (cubit.state.languageCode == 'id') {
                                        await cubit.changeLanguage('en');
                                      } else {
                                        await cubit.changeLanguage('id');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

              // Operational Details Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF212B2F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3E4E55)),
                ),
                child: Column(
                  children: [
                    // Checkpoint Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(AppIcons.meetingRoom, size: 20, color: Color(0xFFA3B1B7)),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('profile.checkpoint'),
                                style: const TextStyle(
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
                    // Connection Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(AppIcons.wifi, size: 20, color: Color(0xFFA3B1B7)),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('profile.connection'),
                                style: const TextStyle(
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
                                connectivity.online
                                    ? context.tr('common.online')
                                    : context.tr('common.offline'),
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

              // Logout Button — dispatch AuthBloc LogoutRequested agar root
              // MaterialApp berpindah kembali ke LoginScreen (AuthUnauthenticated).
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
                      title: context.tr('auth.logoutTitle'),
                      message: context.tr('auth.logoutMessage'),
                      confirmLabel: context.tr('common.logout'),
                    );
                    if (!ok || !context.mounted) return;
                    // Pop profile screen dari navigator stack agar tidak stuck
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    // 1) Bersihkan sesi lokal (staff, checkpoint, mode).
                    context.read<SessionState>().signOut();
                    // 2) Hapus token + emit AuthUnauthenticated → kembali ke login.
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
