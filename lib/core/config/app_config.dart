/// Identitas aplikasi dan nilai bantuan untuk layar login demo.
///
/// Semua layar sudah berbicara ke REST API lewat `ApiService`; yang tersisa di
/// sini hanya konstanta tampilan dan akun demo, bukan penentu perilaku.
library;

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
  static const String demoUsername = 'gate1';
  static const String demoPassword = 'gate123';

  // New getters from env config (optional)
  static String get baseUrl => EnvConfig.baseUrl;
  static bool get needEncrypt => EnvConfig.isNeedEncrypt;
}
