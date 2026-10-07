import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive untuk penyimpanan lokal aman
  await Hive.initFlutter();

  // 2. Inisialisasi Security Encryption & Token DAO
  EncryptionService.initialize();
  await authTokenDao.initialize();

  runApp(const MobileTixApp());
}
