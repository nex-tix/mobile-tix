// File: language_cubit_test.dart
// Unit test untuk LanguageCubit (Commit 2.3 — bahasa persisten id/en)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/bloc/language/language_cubit.dart';

void main() {
  group('LanguageCubit Tests', () {
    late LanguageCubit cubit;

    const boxName = 'preferences_box';
    const langKey = 'language_code';

    setUpAll(() {
      Hive.init(Directory.systemTemp.createTempSync('language_cubit_test').path);
    });

    setUp(() async {
      cubit = LanguageCubit();
      await cubit.initialize();
      await Hive.box(boxName).clear();
      await cubit.loadLanguage();
    });

    group('loadLanguage', () {
      test('default Indonesian saat belum ada preferensi tersimpan', () {
        expect(cubit.state, const Locale('id'));
      });

      test('load English dari storage', () async {
        await Hive.box(boxName).put(langKey, 'en');
        await cubit.loadLanguage();
        expect(cubit.state, const Locale('en'));
      });

      test('load Indonesian dari storage', () async {
        await Hive.box(boxName).put(langKey, 'id');
        await cubit.loadLanguage();
        expect(cubit.state, const Locale('id'));
      });

      test('fallback ke Indonesian saat kode tidak dikenal', () async {
        await Hive.box(boxName).put(langKey, 'fr');
        await cubit.loadLanguage();
        expect(cubit.state, const Locale('id'));
      });
    });

    group('changeLanguage', () {
      test('ubah ke English dan persist ke Hive', () async {
        await cubit.changeLanguage('en');
        expect(cubit.state, const Locale('en'));
        expect(Hive.box(boxName).get(langKey), equals('en'));
      });

      test('ubah ke Indonesian dan persist ke Hive', () async {
        await cubit.changeLanguage('id');
        expect(cubit.state, const Locale('id'));
        expect(Hive.box(boxName).get(langKey), equals('id'));
      });

      test('throw saat kode bahasa tidak didukung', () async {
        expect(() => cubit.changeLanguage('fr'), throwsException);
      });

      test('preferensi bertahan setelah app restart (cubit baru)', () async {
        await cubit.changeLanguage('en');
        final cubitBaru = LanguageCubit();
        await cubitBaru.initialize();
        await cubitBaru.loadLanguage();
        expect(cubitBaru.state, const Locale('en'));
      });
    });

    group('helper checks', () {
      test('isIndonesian true saat id, false saat en', () {
        expect(cubit.isIndonesian(), isTrue);
        expect(cubit.isEnglish(), isFalse);
        cubit.emit(const Locale('en'));
        expect(cubit.isIndonesian(), isFalse);
        expect(cubit.isEnglish(), isTrue);
      });

      test('getCurrentLanguageCode mengembalikan kode yang benar', () {
        expect(cubit.getCurrentLanguageCode(), equals('id'));
        cubit.emit(const Locale('en'));
        expect(cubit.getCurrentLanguageCode(), equals('en'));
      });
    });
  });
}