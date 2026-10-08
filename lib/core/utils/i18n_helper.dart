import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Extension untuk pemanggilan terjemahan yang aman dari exception saat EasyLocalization
/// belum atau tidak diinisialisasi (misal di lingkungan widget test).
extension SafeTrX on BuildContext {
  String trSafe(
    String key,
    String fallback, {
    Map<String, String>? namedArgs,
  }) {
    try {
      final translated = tr(key, namedArgs: namedArgs);
      // Jika easy_localization mengembalikan raw key (artinya tidak ada kamus aktif)
      if (translated == key) {
        if (namedArgs != null && namedArgs.isNotEmpty) {
          var result = fallback;
          namedArgs.forEach((k, v) {
            result = result.replaceAll('{$k}', v);
          });
          return result;
        }
        return fallback;
      }
      return translated;
    } catch (_) {
      if (namedArgs != null && namedArgs.isNotEmpty) {
        var result = fallback;
        namedArgs.forEach((k, v) {
          result = result.replaceAll('{$k}', v);
        });
        return result;
      }
      return fallback;
    }
  }
}
