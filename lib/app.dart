import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/connectivity/demo_connectivity.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/logic/session_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/dashboard/logic/dashboard_state.dart';
import 'features/history/logic/history_state.dart';
import 'features/scanner/logic/scanner_state.dart';
import 'routes/app_routes.dart';
import 'routes/home_shell.dart';
import 'routes/shell_controller.dart';

/// The prototype shell.
///
/// The app has exactly three phases, and which one is on screen follows from the
/// session: splash, sign in, work. Driving the root from state instead of
/// pushing routes means the operator can never land back on a sign-in screen with the
/// system Back gesture — the flow only moves forward, the way a shift does.
///
/// Everything runs on dummy data: no repository, service, or Dio call is invoked by
/// any of these screens.
class MobileTixApp extends StatefulWidget {
  const MobileTixApp({super.key});

  @override
  State<MobileTixApp> createState() => _MobileTixAppState();
}

class _MobileTixAppState extends State<MobileTixApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionState()),
        ChangeNotifierProvider(create: (_) => DemoConnectivity()),
        ChangeNotifierProvider(create: (_) => ScannerState()),
        ChangeNotifierProvider(create: (_) => HistoryState()),
        ChangeNotifierProvider(create: (_) => DashboardState()),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: Consumer<SessionState>(
        builder: (context, session, _) {
          final (key, phase) = _phase(session);
          return MaterialApp(
            title: 'Mobile Ticket Validator',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: session.themeMode,
            onGenerateRoute: onGenerateRoute,
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(key: ValueKey(key), child: phase),
            ),
          );
        },
      ),
    );
  }

  (String, Widget) _phase(SessionState session) {
    if (!_splashDone) {
      return (
        'splash',
        SplashScreen(onDone: () => setState(() => _splashDone = true)),
      );
    }
    if (!session.signedIn) return ('login', const LoginScreen());
    return ('shell', const HomeShell());
  }
}
