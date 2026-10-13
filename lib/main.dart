import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/encryption_service.dart';
import 'core/bloc/theme/theme_cubit.dart';
import 'core/bloc/language/language_cubit.dart';
import 'core/data/dao/offline_queue_dao.dart';
import 'core/data/dao/checkpoint_dao.dart';
import 'core/data/dao/staff_dao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive untuk penyimpanan lokal aman
  await Hive.initFlutter();

  // 2. Daftarkan Hive adapter untuk model custom (wajib sebelum openBox)
  //    QueuedScanAdapter dipakai box antrean scan offline.
  OfflineQueueDAO.registerAdapters();

  // 3. Inisialisasi Security Encryption & DAOs
  EncryptionService.initialize();
  await authTokenDao.initialize();
  await CheckpointDAO().initialize();
  await StaffDAO().initialize();
  await OfflineQueueDAO().initialize();

  // 4. Inisialisasi Global Cubits (Theme & Language)
  final themeCubit = ThemeCubit();
  await themeCubit.initialize();
  await themeCubit.loadTheme();

  final languageCubit = LanguageCubit();
  await languageCubit.initialize();
  await languageCubit.loadLanguage();

  // 5. Inisialisasi EasyLocalization (i18n).
  //    Locale awal diambil dari LanguageCubit (persisted di Hive) agar pilihan
  //    bahasa petugas tetap terjaga antar restart. Persistensi tetap dikelola
  //    LanguageCubit (saveLocale: false) supaya tidak ada dua sumber kebenaran.
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('id'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id'),
      startLocale: languageCubit.state,
      saveLocale: false,
      child: MobileTixApp(
        themeCubit: themeCubit,
        languageCubit: languageCubit,
      ),
    ),
  );
}
