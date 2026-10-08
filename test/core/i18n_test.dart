import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translation Files Validation', () {
    late Map<String, dynamic> idJson;
    late Map<String, dynamic> enJson;

    setUpAll(() {
      final idContent = File('assets/translations/id.json').readAsStringSync();
      final enContent = File('assets/translations/en.json').readAsStringSync();

      idJson = jsonDecode(idContent) as Map<String, dynamic>;
      enJson = jsonDecode(enContent) as Map<String, dynamic>;
    });

    Map<String, String> flatten(Map<String, dynamic> json, [String prefix = '']) {
      final result = <String, String>{};
      json.forEach((key, value) {
        final newKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map<String, dynamic>) {
          result.addAll(flatten(value, newKey));
        } else {
          result[newKey] = value.toString();
        }
      });
      return result;
    }

    test('both id.json and en.json have valid structure and exact same keys', () {
      final idFlat = flatten(idJson);
      final enFlat = flatten(enJson);

      final idKeys = idFlat.keys.toSet();
      final enKeys = enFlat.keys.toSet();

      final missingInEn = idKeys.difference(enKeys);
      final missingInId = enKeys.difference(idKeys);

      expect(missingInEn, isEmpty, reason: 'Keys in id.json but missing in en.json');
      expect(missingInId, isEmpty, reason: 'Keys in en.json but missing in id.json');
      expect(idKeys.length, greaterThan(30));
    });

    test('no translation values are empty', () {
      final idFlat = flatten(idJson);
      final enFlat = flatten(enJson);

      for (final entry in idFlat.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: 'Empty value in id.json for key: ${entry.key}');
      }
      for (final entry in enFlat.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: 'Empty value in en.json for key: ${entry.key}');
      }
    });

    test('named arguments / placeholders match between id and en', () {
      final idFlat = flatten(idJson);
      final enFlat = flatten(enJson);
      final paramRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');

      for (final key in idFlat.keys) {
        final idParams = paramRegex.allMatches(idFlat[key]!).map((m) => m.group(1)!).toSet();
        final enParams = paramRegex.allMatches(enFlat[key]!).map((m) => m.group(1)!).toSet();

        expect(
          idParams,
          equals(enParams),
          reason: 'Placeholder mismatch for key "$key": id=$idParams, en=$enParams',
        );
      }
    });
  });
}
