import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/i18n_helper.dart';
import '../features/dashboard/bloc/dashboard_cubit.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/history/bloc/history_cubit.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/scanner/bloc/scanner_cubit.dart';
import '../features/scanner/bloc/scanner_state.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import 'shell_controller.dart';

/// The working shell with a full-width bottom navigation bar.
///
/// Features:
/// - 3 core destinations: Dashboard, Scan, History
/// - Full-width rectangular bar, rounded top corners, flush to screen edges
/// - Center raised Deep Red Scan button (largest control on the bar)
/// - Smooth hover/press transitions via AnimatedContainer + AnimatedScale
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _lastIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final pendingSync = context.watch<ScannerCubit>().pendingSyncCount;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Saat tab berpindah (mis. dari Scan ke History atau Dashboard),
    // otomatis segarkan data agar data terbaru langsung tampil tanpa perlu pencet filter.
    if (_lastIndex != shell.index) {
      _lastIndex = shell.index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (shell.index == 2) {
          context.read<HistoryCubit>().refresh();
        } else if (shell.index == 0) {
          context.read<DashboardCubit>().refresh();
        }
      });
    }

    return MultiBlocListener(
      listeners: [
        // Otomatis refresh riwayat dan dashboard begitu pemindaian tiket berhasil
        BlocListener<ScannerCubit, ScannerState>(
          listenWhen: (previous, current) => current is ScannerSuccess,
          listener: (context, state) {
            if (state is ScannerSuccess) {
              context.read<HistoryCubit>().refresh();
              context.read<DashboardCubit>().refresh();
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.colors.ground,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Screen pages kept alive in IndexedStack
            IndexedStack(
              index: shell.index,
              children: const [
                DashboardScreen(),
                ScannerScreen(),
                HistoryScreen(),
              ],
            ),

            // Full-width Bottom Navigation Bar (flush to both screen edges)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                key: const Key('bottom-navigation'),
                padding: EdgeInsets.only(top: 10, bottom: bottomInset + 10),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusSheet),
                  ),
                  border: Border(top: BorderSide(color: context.colors.outline)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Tab 1: Dashboard
                    Expanded(
                      child: _NavTab(
                        key: const Key('nav-dashboard'),
                        icon: AppIcons.dashboard,
                        label: context.trSafe('dashboard.title', 'Dashboard'),
                        selected: shell.index == 0,
                        onTap: () {
                          if (shell.index == 0) {
                            context.read<DashboardCubit>().refresh();
                          } else {
                            shell.goIndex(0);
                          }
                        },
                        semanticsLabel: context.trSafe(
                          'dashboard.title',
                          'Dashboard',
                        ),
                      ),
                    ),

                    // Tab 2: Scan — the hero, largest control, dead centre
                    Expanded(
                      child: _ScanNavButton(
                        key: const Key('nav-scan-hero'),
                        selected: shell.index == 1,
                        onTap: () => shell.goIndex(1),
                        badgeCount: pendingSync > 0 ? pendingSync : null,
                      ),
                    ),

                    // Tab 3: History
                    Expanded(
                      child: _NavTab(
                        key: const Key('nav-history'),
                        icon: AppIcons.history,
                        label: context.trSafe('history.title', 'History'),
                        selected: shell.index == 2,
                        onTap: () {
                          if (shell.index == 2) {
                            context.read<HistoryCubit>().refresh();
                          } else {
                            shell.goIndex(2);
                          }
                        },
                        semanticsLabel: context.trSafe(
                          'history.title',
                          'History',
                        ),
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

class _NavTab extends StatefulWidget {
  const _NavTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.selected;
    final color = active || _hovered ? colors.primary : colors.ink;
    final background = active
        ? colors.primaryTint
        : _hovered
        ? colors.surfaceAlt.withValues(alpha: 0.55)
        : Colors.transparent;

    return Semantics(
      label: widget.semanticsLabel,
      selected: widget.selected,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              hoverColor: colors.primaryTint,
              splashColor: colors.primaryTint,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 26, color: color),
                    const SizedBox(height: 5),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: color,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanNavButton extends StatefulWidget {
  const _ScanNavButton({
    super.key,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  State<_ScanNavButton> createState() => _ScanNavButtonState();
}

class _ScanNavButtonState extends State<_ScanNavButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = context.trSafe('scanner.navScan', 'Scan');
    final elevated = widget.selected || _hovered;

    return Semantics(
      label: label,
      selected: widget.selected,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _pressed ? 0.94 : (elevated ? 1.06 : 1),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                      child: Center(
                        child: Icon(
                          AppIcons.qrScanner,
                          size: 36,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                    if (widget.badgeCount != null && widget.badgeCount! > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.surface,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              widget.badgeCount! > 9
                                  ? '9+'
                                  : widget.badgeCount.toString(),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: colors.onSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
