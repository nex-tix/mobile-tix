import 'dart:ui';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import 'shell_controller.dart';

/// The working shell with floating navigation bar matching `newDesign`.
///
/// Features:
/// - 3 core destinations: Dashboard, Scan, History
/// - Floating pill bar (`#212B2F`) with subtle border & glass effect
/// - Center raised Deep Red button for Scan (`#CF4647`)
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();

    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
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

          // Floating Navigation Bar at the bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SizedBox(
              height: 80,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Pill Navigation Bar background
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xF2212B2F),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: const Color(0xFF3E4E55),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Tab 1: Dashboard
                              Expanded(
                                child: _NavTab(
                                  icon: AppIcons.dashboard,
                                  label: 'Dashboard',
                                  selected: shell.index == 0,
                                  onTap: () => shell.goIndex(0),
                                ),
                              ),

                              // Reserved center space for the large Scan button
                              const SizedBox(width: 80),

                              // Tab 3: History
                              Expanded(
                                child: _NavTab(
                                  icon: AppIcons.history,
                                  label: 'History',
                                  selected: shell.index == 2,
                                  onTap: () => shell.goIndex(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Hero Center Scan Button (Elevated & Largest)
                  Positioned(
                    top: 0,
                    child: _ScanNavButton(
                      selected: shell.index == 1,
                      onTap: () => shell.goIndex(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFF5D061) : const Color(0xFFA3B1B7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanNavButton extends StatelessWidget {
  const _ScanNavButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero prominent circular button
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFCF4647),
                  Color(0xFFB83A3B),
                ],
              ),
              border: Border.all(
                color: selected ? const Color(0xFFF5D061) : const Color(0xFF212B2F),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCF4647).withValues(alpha: selected ? 0.65 : 0.4),
                  blurRadius: selected ? 18 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
   AppIcons.qrScanner,
                size: 28,
                color: Color(0xFFF8F6F6),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Scan',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFFF5D061) : const Color(0xFFCF4647),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
