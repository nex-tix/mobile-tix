import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/bloc/language/language_cubit.dart';
import '../../../../core/bloc/theme/theme_cubit.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_status.dart';
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
      backgroundColor: context.colors.ground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.ink),
        title: Text(
          context.trSafe('profile.title', 'Profil Petugas'),
          style: TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: context.colors.ink,
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
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSheet),
                  border: Border.all(color: context.colors.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.surfaceAlt,
                        border: Border.all(color: context.colors.outline),
                      ),
                      child: ClipOval(
                        child: Center(
                          child: Text(
                            staff?.initials ?? 'R',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
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
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            staff?.role ??
                                context.trSafe(
                                  'profile.defaultRole',
                                  'Gate Staff · Shift Utama',
                                ),
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
              ),
              const SizedBox(height: 20),

              // Settings Card: Theme & Language
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: context.colors.outline),
                ),
                child: Column(
                  children: [
                    // Theme Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      leading: Icon(
                        AppIcons.sun,
                        size: 22,
                        color: context.colors.inkMuted,
                      ),
                      title: Text(
                        context.trSafe('profile.theme', 'Tema'),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.inkMuted,
                        ),
                      ),
                      trailing: BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          final String label;
                          switch (themeMode) {
                            case ThemeMode.light:
                              label = context.trSafe('common.light', 'Terang');
                              break;
                            case ThemeMode.dark:
                              label = context.trSafe('common.dark', 'Gelap');
                              break;
                            case ThemeMode.system:
                              label = context.trSafe('common.system', 'Sistem');
                              break;
                          }
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
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
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.outline,
                    ),

                    // Language Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      leading: Icon(
                        AppIcons.language,
                        size: 22,
                        color: context.colors.inkMuted,
                      ),
                      title: Text(
                        context.trSafe('profile.language', 'Bahasa'),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.inkMuted,
                        ),
                      ),
                      trailing: BlocBuilder<LanguageCubit, Locale>(
                        builder: (context, state) {
                          return Text(
                            state.languageCode == 'en'
                                ? context.trSafe('common.english', 'English')
                                : context.trSafe(
                                    'common.indonesian',
                                    'Indonesia',
                                  ),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
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
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: context.colors.outline),
                ),
                child: Column(
                  children: [
                    // Checkpoint Row
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed('/checkpoint'),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.meetingRoom,
                                  size: 20,
                                  color: context.colors.inkMuted,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  context.trSafe(
                                    'profile.checkpoint',
                                    'Checkpoint',
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  checkpoint?.gate ?? 'Gate 1',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  AppIcons.arrowForward,
                                  size: 16,
                                  color: context.colors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.outline,
                    ),
                    // Connection Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.wifi,
                                size: 20,
                                color: context.colors.inkMuted,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                context.trSafe('profile.connection', 'Koneksi'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          ConnectionPill(
                            online: connectivity.online,
                            onToggle: () =>
                                context.read<DemoConnectivity>().toggle(),
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
                    backgroundColor: context.colors.surface,
                    side: BorderSide(color: context.colors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: context.trSafe(
                        'auth.logoutTitle',
                        'Keluar dari akun?',
                      ),
                      message: context.trSafe(
                        'auth.logoutMessage',
                        'Sesi saat ini akan diakhiri.',
                      ),
                      confirmLabel: context.trSafe('common.logout', 'Logout'),
                    );
                    if (!ok || !context.mounted) return;
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    context.read<SessionState>().signOut();
                    context.read<AuthBloc>().add(const LogoutRequested());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.logout,
                        size: 18,
                        color: context.colors.dangerRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.trSafe('common.logout', 'Logout'),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.dangerRed,
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
