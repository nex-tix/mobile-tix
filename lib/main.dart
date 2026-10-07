import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/encryption_service.dart';
import 'core/bloc/theme/theme_cubit.dart';
import 'core/bloc/language/language_cubit.dart';
import 'core/data/dao/offline_queue_dao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive untuk penyimpanan lokal aman
  await Hive.initFlutter();

  // 2. Daftarkan Hive adapter untuk model custom (wajib sebelum openBox)
  //    QueuedScanAdapter dipakai box antrean scan offline.
  OfflineQueueDAO.registerAdapters();

  // 3. Inisialisasi Security Encryption & Token DAO
  EncryptionService.initialize();
  await authTokenDao.initialize();

  // 4. Inisialisasi Global Cubits (Theme & Language)
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
