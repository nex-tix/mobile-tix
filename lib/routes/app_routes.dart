import 'package:flutter/material.dart';
import 'package:mobile_tix/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile_tix/features/auth/presentation/screens/profile_screen.dart';
import 'package:mobile_tix/features/checkpoint/presentation/screens/checkpoint_screen.dart';
import 'package:mobile_tix/core/data/dao/token_jwt_dao.dart';

class AppRoutes {
  const AppRoutes._();

  static const String profile = '/profile';
  static const String checkpoint = '/checkpoint';
}

/// Pushed routes dengan penjaga otentikasi (route guard) untuk web & deep-link.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final token = TokenJwtDAO().getToken();
  final isAuthenticated = token != null && token.isNotEmpty;

  switch (settings.name) {
    case AppRoutes.profile:
      return MaterialPageRoute(
        builder: (_) => isAuthenticated ? const ProfileScreen() : const LoginScreen(),
        settings: settings,
      );
    case AppRoutes.checkpoint:
      return MaterialPageRoute(
        builder: (_) => isAuthenticated ? const CheckpointScreen(isSwitch: true) : const LoginScreen(),
        settings: settings,
      );
    default:
      return null;
  }
}
