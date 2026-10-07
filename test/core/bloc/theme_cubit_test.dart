// File: theme_cubit_test.dart
// Unit test untuk ThemeCubit (Commit 2.2 — tema persisten light/dark/system)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/bloc/theme/theme_cubit.dart';

void main() {
  group('ThemeCubit Tests', () {
    late ThemeCubit cubit;

    // Key Hive yang digunakan ThemeCubit (harus sama dengan di cubit)
    const boxName = 'preferences_box';
    const themeKey = 'theme_mode';

    setUpAll(() {
      // Init Hive di folder temp — aman untuk unit test (tanpa Flutter binding)
      Hive.init(Directory.systemTemp.createTempSync('theme_cubit_test').path);
    });

    setUp(() async {
      // Cubit baru tiap test + buka box preferences
      cubit = ThemeCubit();
      await cubit.initialize();

      // Reset preferensi supaya tiap test mulai dari kondisi bersih
      await Hive.box(boxName).clear();

      // Load tema (default light karena box kosong)
      await cubit.loadTheme();
    });

    // Catatan: cubit TIDAK di-close di tearDown karena close() ikut menutup
    // shared box 'preferences_box' yang dipakai test berikutnya.

    group('loadTheme', () {
      test('default light saat belum ada preferensi tersimpan', () {
        expect(cubit.state, ThemeMode.light);
      });

      test('load tema gelap dari storage', () async {
        // Simpan 'ThemeMode.dark' langsung ke box (format internal cubit)
        await Hive.box(boxName).put(themeKey, 'ThemeMode.dark');

        await cubit.loadTheme();

        expect(cubit.state, ThemeMode.dark);
      });

      test('load tema system dari storage', () async {
        await Hive.box(boxName).put(themeKey, 'ThemeMode.system');

        await cubit.loadTheme();

        expect(cubit.state, ThemeMode.system);
      });

      test('fallback ke light saat nilai tersimpan tidak dikenal', () async {
        await Hive.box(boxName).put(themeKey, 'ThemeMode.gelap-nya');

        await cubit.loadTheme();

        expect(cubit.state, ThemeMode.light);
      });
    });

    group('toggleTheme', () {
      test('light → dark', () async {
        expect(cubit.state, ThemeMode.light);

        await cubit.toggleTheme();

        expect(cubit.state, ThemeMode.dark);
      });

      test('dark → light', () async {
        await cubit.setThemeMode(ThemeMode.dark);

        await cubit.toggleTheme();

        expect(cubit.state, ThemeMode.light);
      });

      test('system → light (safe default)', () async {
        await cubit.setThemeMode(ThemeMode.system);

        await cubit.toggleTheme();

        expect(cubit.state, ThemeMode.light);
      });

      test('hasil toggle tersimpan ke Hive', () async {
        await cubit.toggleTheme();

        expect(Hive.box(boxName).get(themeKey), equals('ThemeMode.dark'));
      });
    });

    group('setThemeMode', () {
      test('set eksplisit dark dan persist ke Hive', () async {
        await cubit.setThemeMode(ThemeMode.dark);

        expect(cubit.state, ThemeMode.dark);
        expect(Hive.box(boxName).get(themeKey), equals('ThemeMode.dark'));
      });

      test('set eksplisit system dan persist ke Hive', () async {
        await cubit.setThemeMode(ThemeMode.system);

        expect(cubit.state, ThemeMode.system);
        expect(Hive.box(boxName).get(themeKey), equals('ThemeMode.system'));
      });

      test('preferensi bertahan setelah app restart (cubit baru)', () async {
        // Simulasi pemilihan user
        await cubit.setThemeMode(ThemeMode.dark);

        // Simulasi restart: cubit baru load dari storage yang sama
        final cubitBaru = ThemeCubit();
        await cubitBaru.initialize();
        await cubitBaru.loadTheme();

        expect(cubitBaru.state, ThemeMode.dark);
      });
    });

    group('helper checks', () {
      test('isLightMode true saat light, false saat dark', () async {
        expect(cubit.isLightMode(), isTrue);
        expect(cubit.isDarkMode(), isFalse);

        await cubit.setThemeMode(ThemeMode.dark);

        expect(cubit.isLightMode(), isFalse);
        expect(cubit.isDarkMode(), isTrue);
      });
    });
  });
}
