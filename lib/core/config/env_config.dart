import 'package:flutter/foundation.dart';

/// Environment configuration loader
/// 
/// Loads dari .env file atau environment variables.
/// Gunakan String.fromEnvironment untuk production builds.
class EnvConfig {
  const EnvConfig._();

  // API Configuration
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081/api';
    }
    return 'http://localhost:8081/api';
  }

  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30000,
  );

  // Encryption & Security
  static const bool isNeedEncrypt = bool.fromEnvironment(
    'IS_NEED_ENCRYPT',
    defaultValue: false,
  );

  static const String secretKey = String.fromEnvironment(
    'SECRET_KEY',
    defaultValue: '1234567891011121314151617181920212223242526272829303132',
  );

  static const String iv = String.fromEnvironment(
    'IV',
    defaultValue: '1234567890123456',
  );

  // Mock API Flag
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );

  // Request Signature
  static const String signatureSecret = String.fromEnvironment(
    'SIGNATURE_SECRET',
    defaultValue: 'rayaaldywisma123',
  );

  // App Config
  static const String channelCd = String.fromEnvironment(
    'CHANNEL_CD',
    defaultValue: '01',
  );

  static const String defaultLanguage = String.fromEnvironment(
    'DEFAULT_LANGUAGE',
    defaultValue: 'id',
  );

  // Feature Flags
  static const bool enableOfflineQueue = bool.fromEnvironment(
    'ENABLE_OFFLINE_QUEUE',
    defaultValue: true,
  );

  static const bool enableAutoLogout = bool.fromEnvironment(
    'ENABLE_AUTO_LOGOUT',
    defaultValue: true,
  );

  static const bool enableAudioFeedback = bool.fromEnvironment(
    'ENABLE_AUDIO_FEEDBACK',
    defaultValue: true,
  );

  // Token Configuration
  static const int tokenTtlHours = 12;
  static const int tokenRefreshBeforeExpiryMinutes = 30;
  static const int autoLogoutIdleMinutes = 15;
  static const int autoLogoutWarningSeconds = 60;
}
