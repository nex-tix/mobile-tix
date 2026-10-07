import 'package:intl/intl.dart';

/// Dummy-data formatting. Everything here formats a value the UI already holds —
/// no parsing of backend payloads, because there is no backend in this stage.
class Fmt {
  const Fmt._();

  static final DateFormat _clock = DateFormat('HH:mm');
  static final DateFormat _clockSeconds = DateFormat('HH:mm:ss');
  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _monthDay = DateFormat('d MMM', 'id_ID');
  static final NumberFormat _thousands = NumberFormat.decimalPattern('id_ID');

  /// `14:32`
  static String clock(DateTime t) => _clock.format(t);

  /// `14:32:07`
  static String clockSeconds(DateTime t) => _clockSeconds.format(t);

  /// `Selasa, 6 Oktober 2026`
  static String fullDate(DateTime t) {
    try {
      return _fullDate.format(t);
    } catch (_) {
      return _monthDay.format(t);
    }
  }

  /// `1.245`
  static String count(int value) => _thousands.format(value);

  /// `96%` — integer share, never a fake decimal.
  static String percent(int part, int whole) {
    if (whole <= 0) return '0%';
    return '${(part / whole * 100).round()}%';
  }

  /// `2 tiket`
  static String tickets(int n) => '$n tiket';

  /// Absolute href-free duration used by the "last used" line: `14:02` → `30 menit lalu`
  static String ago(DateTime t, DateTime now) {
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  /// Day-group header for the log: `HARI INI`, `KEMARIN`, `4 OKT`.
  static String dayGroup(DateTime t, DateTime now) {
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return _monthDay.format(t).toUpperCase();
  }
}
