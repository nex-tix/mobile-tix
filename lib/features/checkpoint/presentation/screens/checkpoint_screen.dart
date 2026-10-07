import 'package:flutter/material.dart';
import 'package:mobile_tix/core/bloc/auth/auth_bloc.dart';
import 'package:mobile_tix/core/bloc/auth/auth_event.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/logic/session_state.dart';
import '../../data/dummy_checkpoints.dart';
import '../../data/models/checkpoint.dart';
import '../widgets/checkpoint_tile.dart';

/// Screen 2: Checkpoint Selection matching `newDesign/2._checkpoint_selection/code.html`.
class CheckpointScreen extends StatefulWidget {
  const CheckpointScreen({super.key, this.isSwitch = false});

  final bool isSwitch;

  @override
  State<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  Checkpoint? _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<SessionState>().checkpoint ?? dummyCheckpoints.first;
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    final session = context.read<SessionState>();
    session.selectCheckpoint(selected);
    if (widget.isSwitch) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _signOut() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda akan kembali ke layar login.',
      confirmLabel: 'KELUAR',
    );
    if (!ok || !mounted) return;
        // Bersihkan sesi lokal, lalu logout via AuthBloc → kembali ke LoginScreen.
        context.read<SessionState>().signOut();
        context.read<AuthBloc>().add(const LogoutRequested());
        if (widget.isSwitch) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
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
                      icon: const Icon(AppIcons.arrowBack, color: Color(0xFFF8F6F6)),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Kembali',
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(AppIcons.logout, color: Color(0xFFA3B1B7), size: 20),
                    onPressed: _signOut,
                    tooltip: 'Logout',
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
                  children: const [
                    Text(
                      'Select checkpoint',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF8F6F6),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Choose your active checkpoint',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: Color(0xFFA3B1B7),
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
                          child: const Center(
                            child: Text(
                              'Masuk ke Gate',
                              style: TextStyle(
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
