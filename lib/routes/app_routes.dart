import 'package:flutter/material.dart';
import 'package:mobile_tix/features/auth/presentation/screens/profile_screen.dart';

class AppRoutes {
  const AppRoutes._();

  /// No additional pushed routes — all navigation is handled via AppShell.
}

/// Pushed routes. Currently empty.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/profile':
      return MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
        settings: settings,
      );
    default:
      return null;
  }
}
