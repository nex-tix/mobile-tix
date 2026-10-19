// File: ticket_code.dart
// Membaca kode tiket dari apa pun yang dikirim pemindai.

/// Pola kode tiket yang dibuat POS: awalan `TKT-` (individu) atau `GRP-`
/// (rombongan), lalu 4 blok @4 karakter — mis. `TKT-4ES7-P7R8-8DSW-95W9`.
final RegExp _ticketPattern = RegExp(r'(TKT|GRP)(-[A-Z0-9]{4}){4}');

/// Penanda nilai di payload berbentuk key-value (`code=…`), dipakai QR POS
/// maupun URL verifikasi.
final RegExp _codeMarker = RegExp(r'code=([^|&\s]+)', caseSensitive: false);

final RegExp _whitespace = RegExp(r'\s+');

/// Penanda jumlah kuota/tamu di payload QR bila disertakan (mis. `visitors=10`).
final RegExp _visitorsMarker = RegExp(
  r'(?:visitors?|total_visitors|pax|quota)=(\d+)',
  caseSensitive: false,
);

/// Kode tiket yang siap dikirim ke API.
///
/// QR yang dicetak POS tidak berisi kode tiket polos, melainkan payload
/// terstruktur:
///
/// ```text
/// TICKET|code=GRP-2HPG-4FWB-GMFR-NRXW|transaction=6|status=active
/// ```
///
/// Kalau payload itu dikirim apa adanya, API mencari `ticket_code` yang sama
/// dengan seluruh payload dan tidak menemukan apa pun — gate melihat
/// TIKET TIDAK VALID padahal tiketnya sah. Kelas ini mengambil kode tiketnya
/// dari payload, dari URL, atau dari kode yang diketik manual, lalu
/// merapikannya (huruf besar, tanpa spasi) sehingga satu tiket selalu sampai
/// ke API dalam bentuk yang sama.
class TicketCode {
  const TicketCode._();

  /// Kode tiket hasil normalisasi; string kosong bila masukan kosong.
  ///
  /// Kode yang tidak dikenali pola tiket tetap diteruskan apa adanya (huruf
  /// besar, spasi dibuang) supaya gate tetap menerima verdict dari server,
  /// bukan kegagalan lokal.
  static String parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final candidate = (_codeMarker.firstMatch(trimmed)?.group(1) ?? trimmed)
        .replaceAll(_whitespace, '')
        .toUpperCase();

    final match = _ticketPattern.firstMatch(candidate);
    return match?.group(0) ?? candidate;
  }

  /// True bila [raw] sudah berbentuk kode tiket (setelah normalisasi).
  static bool looksLikeTicket(String raw) =>
      _ticketPattern.hasMatch(parse(raw));

  /// True bila [raw] adalah tiket rombongan (`GRP-`).
  static bool isGroup(String raw) => parse(raw).startsWith('GRP');

  /// Ambil estimasi kuota/tamu dari payload QR jika tersedia (mis. `visitors=10`).
  static int? parseQuota(String raw) {
    final match = _visitorsMarker.firstMatch(raw);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}
