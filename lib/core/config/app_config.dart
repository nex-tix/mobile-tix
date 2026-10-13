/// Identitas aplikasi dan konstanta tampilan.
///
/// Semua layar sudah berbicara ke REST API lewat `ApiService`; yang tersisa di
/// sini hanya konstanta tampilan, bukan penentu perilaku. Kredensial petugas
/// tidak pernah disimpan di aplikasi.
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

  // New getters from env config (optional)
  static String get baseUrl => EnvConfig.baseUrl;
  static bool get needEncrypt => EnvConfig.isNeedEncrypt;
}
