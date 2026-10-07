import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/connectivity/demo_connectivity.dart';
import 'core/theme/app_theme.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/bloc/auth/auth_state.dart';
import 'core/bloc/auth/auth_event.dart';
import 'core/bloc/token_jwt/token_jwt_cubit.dart';
import 'core/bloc/theme/theme_cubit.dart';
import 'core/bloc/language/language_cubit.dart';
import 'core/data/dao/token_jwt_dao.dart';
import 'core/data/repositories/auth_repository.dart';
import 'core/services/api_service.dart';
import 'core/services/token_refresh_service.dart';
import 'core/services/auto_logout_service.dart';
import 'core/services/auto_logout_observer.dart';
import 'core/services/mock_api_adapter.dart';
import 'features/auth/logic/session_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/dashboard/logic/dashboard_state.dart';
import 'features/history/logic/history_state.dart';
import 'features/scanner/logic/scanner_state.dart';
import 'routes/app_routes.dart';
import 'routes/home_shell.dart';
import 'routes/shell_controller.dart';

// ==================== AUTH & SECURITY SINGLETONS ====================
final TokenJwtDAO authTokenDao = TokenJwtDAO();
final ApiService authApiService = ApiService();
final AuthRepository authRepository = AuthRepository(authApiService, authTokenDao);
final TokenRefreshService authTokenRefreshService = TokenRefreshService();
final TokenJwtCubit authTokenCubit = TokenJwtCubit(authTokenDao, authTokenRefreshService);
final AutoLogoutService authAutoLogoutService = AutoLogoutService();
final AutoLogoutObserver authAutoLogoutObserver =
    AutoLogoutObserver(logoutService: authAutoLogoutService);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// The main application shell.
///
/// Menerima [themeCubit] dan [languageCubit] dari main() agar state global
/// tema & bahasa bisa di-inject ke root MultiBlocProvider (Commit 2.4).
class MobileTixApp extends StatefulWidget {
  // Global cubit instances — dibuat & di-load di main() sebelum runApp
  final ThemeCubit themeCubit;
  final LanguageCubit languageCubit;

  const MobileTixApp({
    super.key,
    required this.themeCubit,
    required this.languageCubit,
  });

  @override
  State<MobileTixApp> createState() => _MobileTixAppState();
}

class _MobileTixAppState extends State<MobileTixApp> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _setupSecurityServices();
  }

  void _setupSecurityServices() {
    // 1. Proactive Token Refresh
    authTokenRefreshService.onRefreshToken = () async {
      final currentToken = authTokenDao.getToken();
      if (currentToken == null || currentToken.isEmpty) return null;
      final newToken = MockApiAdapter.generateMockJwt();
      await authTokenDao.saveToken(newToken);
      authTokenCubit.saveToken(newToken);
      authApiService.setToken(newToken);
      return newToken;
    };

    authTokenRefreshService.onRefreshFailed = () {
      authAutoLogoutService.forceLogout();
    };

    // 2. ApiService 401 Hooks
    authApiService.onRefreshToken = authTokenRefreshService.onRefreshToken;
    authApiService.onSessionExpired = () {
      authAutoLogoutService.forceLogout();
    };

    // 3. Auto Logout Hooks
    authAutoLogoutService.onShowWarning = _showAutoLogoutWarning;
    authAutoLogoutService.onForceLogout = _handleForceLogout;
    authAutoLogoutService.onStayLoggedIn = () async {
      await authTokenRefreshService.onRefreshToken?.call();
    };
  }

  void _showAutoLogoutWarning() {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF18202C),
        title: const Text('Peringatan Sesi', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sesi Anda akan segera berakhir karena tidak ada aktivitas. Tetap masuk atau keluar sekarang?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
              authAutoLogoutService.forceLogout();
            },
            child: const Text('Keluar', style: TextStyle(color: Color(0xFFCF4647))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A93C)),
            onPressed: () {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
              authAutoLogoutService.stayLoggedIn();
            },
            child: const Text('Tetap Masuk', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _handleForceLogout() {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null && Navigator.of(navContext).canPop()) {
      Navigator.of(navContext).pop();
    }
    authTokenCubit.clearToken();
    authApiService.clearToken();
    authTokenRefreshService.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Global state cubits (Commit 2.4)
        BlocProvider<ThemeCubit>.value(value: widget.themeCubit),
        BlocProvider<LanguageCubit>.value(value: widget.languageCubit),
        // Auth & Security dependencies
        BlocProvider<TokenJwtCubit>.value(value: authTokenCubit),
        Provider<AuthRepository>.value(value: authRepository),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: authRepository,
            tokenCubit: authTokenCubit,
            apiService: authApiService,
          )..add(const AuthCheckRequested()),
        ),
        // Legacy providers (akan dihapus di Fase 6)
        ChangeNotifierProvider(create: (_) => SessionState()),
        ChangeNotifierProvider(create: (_) => DemoConnectivity()),
        ChangeNotifierProvider(create: (_) => ScannerState()),
        ChangeNotifierProvider(create: (_) => HistoryState()),
        ChangeNotifierProvider(create: (_) => DashboardState()),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return BlocConsumer<AuthBloc, AuthState>(
                listener: (context, authState) {
                  if (authState is AuthAuthenticated) {
                    authAutoLogoutService.resetTimer();
                    final token = authTokenDao.getToken();
                    if (token != null && token.isNotEmpty) {
                      authTokenRefreshService.scheduleNextRefresh(token);
                    }
                  } else if (authState is AuthUnauthenticated) {
                    authAutoLogoutService.stop();
                    authTokenRefreshService.cancel();
                  }
                },
                builder: (context, authState) {
                  final (key, phase) = _phase(authState);
                  return Listener(
                    onPointerDown: (_) => authAutoLogoutService.resetTimer(),
                    behavior: HitTestBehavior.translucent,
                    child: MaterialApp(
                      navigatorKey: rootNavigatorKey,
                      navigatorObservers: [authAutoLogoutObserver],
                      title: 'Mobile Ticket Validator',
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light(),
                      darkTheme: AppTheme.dark(),
                      themeMode: themeMode, // Dynamic dari ThemeCubit
                      locale: locale, // Dynamic dari LanguageCubit
                      onGenerateRoute: onGenerateRoute,
                      home: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(key: ValueKey(key), child: phase),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  (String, Widget) _phase(AuthState state) {
    if (!_splashDone) {
      return (
        'splash',
        SplashScreen(onDone: () => setState(() => _splashDone = true)),
      );
    }
    if (state is! AuthAuthenticated) return ('login', const LoginScreen());
    return ('shell', const HomeShell());
  }
}
