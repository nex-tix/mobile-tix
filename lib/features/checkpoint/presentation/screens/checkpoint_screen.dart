import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../auth/logic/session_state.dart';
import '../../data/dummy_checkpoints.dart';
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

  @override
  void initState() {
    super.initState();
    // Default seleksi ke checkpoint yang sedang aktif di session (jika ada)
    final current = context.read<SessionState>().checkpoint;
    _selected = current ?? (dummyCheckpoints.isNotEmpty ? dummyCheckpoints.first : null);
  }

  void _confirm() {
    if (_selected == null) return;
    context.read<SessionState>().selectCheckpoint(_selected!);
    if (widget.isSwitch) {
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
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
                    icon: Icon(AppIcons.logout, color: context.colors.inkMuted, size: 20),
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
                      context.trSafe('checkpoint.selectTitle', 'Pilih checkpoint'),
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final cp in dummyCheckpoints)
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
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFCF4647),
                            Color(0xFFB83A3B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _selected != null ? _confirm : null,
                          child: Center(
                            child: Text(
                              context.trSafe('checkpoint.enterGate', 'Masuk ke Gate'),
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF8F6F6),
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
