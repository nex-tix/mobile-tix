/// App config for the UI prototype stage. Dummy values only — nothing here talks
/// to a backend; the Dio layer is untouched and unused by these screens.
import 'package:mobile_tix/core/config/env_config.dart';

class AppConfig {
  const AppConfig._();

  static const String appName = 'Mobile Ticket Validator';
  static const String productWordmark = 'Gate Validator';
  static const String version = '1.0.0';
  static const String buildLabel = 'Demo UI';

  static const String logoAsset = 'assets/images/logo.png';
  static const String kecakBackgroundAsset = 'assets/images/kecak-background.jpg';

  /// Shown on the login screen as a demo note.
  static const String demoUsername = 'admin.gate';
  static const String demoPassword = 'gate2026';

  /// The prototype answers every outcome from local dummy data.
  static const bool uiOnly = true;

  // New getters from env config (optional)
  static String get baseUrl => EnvConfig.baseUrl;
  static bool get needEncrypt => EnvConfig.isNeedEncrypt;
}
