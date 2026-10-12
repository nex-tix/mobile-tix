import 'package:flutter/material.dart';
import 'package:mobile_tix/features/auth/presentation/screens/profile_screen.dart';
import 'package:mobile_tix/features/checkpoint/presentation/screens/checkpoint_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String profile = '/profile';
  static const String checkpoint = '/checkpoint';
}

/// Pushed routes.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.profile:
      return MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
        settings: settings,
      );
    case AppRoutes.checkpoint:
      return MaterialPageRoute(
        builder: (_) => const CheckpointScreen(isSwitch: true),
        settings: settings,
      );
    default:
      return null;
  }
}
