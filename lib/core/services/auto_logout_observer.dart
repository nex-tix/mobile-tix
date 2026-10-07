import 'package:flutter/widgets.dart';
import 'auto_logout_service.dart';

/// NavigatorObserver yang memicu reset timer AutoLogoutService
/// setiap kali ada navigasi rute (push, pop, replace).
class AutoLogoutObserver extends NavigatorObserver {
  final AutoLogoutService logoutService;

  AutoLogoutObserver({required this.logoutService});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    logoutService.resetTimer();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    logoutService.resetTimer();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    logoutService.resetTimer();
  }
}
