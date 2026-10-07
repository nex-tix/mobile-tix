import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/encryption_service.dart';
import 'core/bloc/theme/theme_cubit.dart';
import 'core/bloc/language/language_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive untuk penyimpanan lokal aman
  await Hive.initFlutter();

  // 2. Inisialisasi Security Encryption & Token DAO
  EncryptionService.initialize();
  await authTokenDao.initialize();

  // 3. Inisialisasi Global Cubits (Theme & Language)
  final themeCubit = ThemeCubit();
  await themeCubit.initialize();
  await themeCubit.loadTheme();

  final languageCubit = LanguageCubit();
  await languageCubit.initialize();
  await languageCubit.loadLanguage();

  runApp(MobileTixApp(
    themeCubit: themeCubit,
    languageCubit: languageCubit,
  ));
}
