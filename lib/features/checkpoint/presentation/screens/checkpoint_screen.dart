import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../auth/logic/session_state.dart';
import '../../../../core/data/dao/checkpoint_dao.dart';
import '../../data/models/checkpoint.dart';
import '../widgets/checkpoint_tile.dart';

/// Screen 2: Checkpoint Selection matching `newDesign/2._checkpoint_selection/code.html`.
///
/// Features:
/// - Screen title & subtitle: "Pilih checkpoint aktif Anda"
/// - List of selectable checkpoints with custom radio & active outline
/// - Primary Action button at bottom: "Masuk ke Gate"
/// - Top bar with back button (if switching) & logout action
class CheckpointScreen extends StatefulWidget {
  const CheckpointScreen({super.key, this.isSwitch = false});

  /// `true` jika dibuka dari profil/pengaturan untuk ganti checkpoint (bisa pop kembali)
  final bool isSwitch;

  @override
  State<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  Checkpoint? _selected;

  List<Checkpoint> get _allCheckpoints {
    final cached = CheckpointDAO().getCheckpoints();
    if (cached != null && cached.isNotEmpty) {
      return cached.map((e) => Checkpoint.fromJson(e)).toList();
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    // Default seleksi ke checkpoint yang sedang aktif di session (jika ada)
    final current = context.read<SessionState>().checkpoint;
    _selected = current ?? (_allCheckpoints.isNotEmpty ? _allCheckpoints.first : null);
  }

  void _confirm() {
    if (_selected == null) return;
    context.read<SessionState>().selectCheckpoint(_selected!);
    AppSnackbar.success(
      context,
      context.trSafe(
        'checkpoint.switchedSuccess',
        'Checkpoint berhasil diubah ke {gate}',
        namedArgs: {'gate': _selected!.gate},
      ),
    );
    Navigator.of(context).maybePop();
  }

  void _signOut() {
    context.read<SessionState>().signOut();
    context.read<AuthBloc>().add(const LogoutRequested());
    if (widget.isSwitch) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isSwitch)
                    IconButton(
                      icon: Icon(AppIcons.arrowBack, color: context.colors.ink),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: context.trSafe('checkpoint.back', 'Kembali'),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      AppIcons.logout,
                      color: context.colors.inkMuted,
                      size: 20,
                    ),
                    onPressed: _signOut,
                    tooltip: context.trSafe('common.logout', 'Logout'),
                  ),
                ],
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trSafe(
                        'checkpoint.selectTitle',
                        'Pilih checkpoint',
                      ),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: context.colors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.trSafe(
                        'checkpoint.selectSubtitle',
                        'Pilih checkpoint aktif Anda',
                      ),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: context.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Checkpoint Options List
            Expanded(
              child: _allCheckpoints.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.door,
                              size: 48,
                              color: context.colors.inkMuted,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              context.trSafe('common.noData', 'Data tidak ada'),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.colors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.trSafe(
                                'checkpoint.emptySubtitle',
                                'Data checkpoint belum tersedia atau perangkat sedang offline.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 13,
                                color: context.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        for (final cp in _allCheckpoints)
                          CheckpointTile(
                            checkpoint: cp,
                            selected: _selected?.id == cp.id,
                            onTap: () {
                              setState(() => _selected = cp);
                            },
                          ),
                      ],
                    ),
            ),

            // Bottom Action Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _selected != null
                            ? context.colors.primary
                            : context.colors.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _selected != null ? _confirm : null,
                          child: Center(
                            child: Text(
                              context.trSafe(
                                'checkpoint.enterGate',
                                'Masuk ke Gate',
                              ),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _selected != null
                                    ? context.colors.onPrimary
                                    : context.colors.inkMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
