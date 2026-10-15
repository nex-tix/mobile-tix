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
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_status.dart';
import '../../../../core/data/dao/checkpoint_dao.dart';
import '../../../checkpoint/data/dummy_checkpoints.dart';
import '../../../checkpoint/data/models/checkpoint.dart';
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

    // Nama diambil dari akun yang benar-benar login (gate_users).
    final staffName = staff?.displayName ?? '';
    // Peran tidak ada di tabel petugas, jadi labelnya dari kamus.
    final staffRole = context.trSafe('profile.defaultRole', 'Petugas Gate');

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
                            staff?.initials ?? '',
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
                            staffName.isEmpty
                                ? context.trSafe(
                                    'profile.unknownStaff',
                                    'Petugas belum dikenal',
                                  )
                                : staffName,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            staffRole,
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
                      onTap: () => _showCheckpointPicker(context),
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
                                  AppIcons.chevronRight,
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
                            isChecking: connectivity.isChecking,
                            onRefresh: () async {
                              final ok = await context
                                  .read<DemoConnectivity>()
                                  .checkConnection();
                              if (context.mounted) {
                                if (ok) {
                                  AppSnackbar.success(
                                    context,
                                    context.trSafe(
                                      'connectivity.connectedSuccess',
                                      'Sinyal terhubung kembali (Online)',
                                    ),
                                  );
                                } else {
                                  AppSnackbar.warning(
                                    context,
                                    context.trSafe(
                                      'connectivity.stillOffline',
                                      'Sinyal belum ditemukan, masih Mode Offline',
                                    ),
                                  );
                                }
                              }
                            },
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

  void _showCheckpointPicker(BuildContext context) {
    final session = context.read<SessionState>();
    final current = session.checkpoint;
    final colors = context.colors;

    AppSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.trSafe('checkpoint.switchTitle', 'Ganti Checkpoint'),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.close, size: 20, color: colors.inkMuted),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            context.trSafe(
              'checkpoint.selectSubtitle',
              'Pilih checkpoint aktif Anda',
            ),
            style: TextStyle(
              fontSize: 13,
              color: colors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final cached = CheckpointDAO().getCheckpoints();
              final checkpoints = cached != null && cached.isNotEmpty
                  ? cached.map((e) => Checkpoint.fromJson(e)).toList()
                  : dummyCheckpoints;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final cp in checkpoints) ...[
                    _CheckpointPickerTile(
                      checkpoint: cp,
                      isSelected: current?.id == cp.id,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (current?.id != cp.id) {
                          session.selectCheckpoint(cp);
                          AppSnackbar.success(
                            context,
                            context.trSafe(
                              'checkpoint.switchedSuccess',
                              'Checkpoint berhasil diubah ke {gate}',
                              namedArgs: {'gate': cp.gate},
                            ),
                          );
                        }
                      },
                    ),
                    if (cp != checkpoints.last) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckpointPickerTile extends StatelessWidget {
  const _CheckpointPickerTile({
    required this.checkpoint,
    required this.isSelected,
    required this.onTap,
  });

  final Checkpoint checkpoint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceAlt : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primaryTint : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outline,
                  ),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.meetingRoom,
                    size: 18,
                    color: isSelected ? colors.primary : colors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          checkpoint.gate,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                        if (!checkpoint.open) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryTint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DITUTUP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (checkpoint.name.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        checkpoint.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.inkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  AppIcons.checkCircle,
                  size: 20,
                  color: colors.primary,
                )
              else
                Icon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: colors.inkMuted.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

