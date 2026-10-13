import 'package:flutter/foundation.dart';

/// Petugas gate yang sedang login.
///
/// Semua field datang dari server (`gate_users` lewat balikan `/login`, bentuk
/// `{ id, name, username, phone }`). Tidak ada nama atau peran bawaan di kelas
/// ini dengan sengaja: kalau server belum memberi data petugas, UI harus
/// menampilkan apa adanya — bukan mengarang "Admin Gate" seperti sebelumnya.
@immutable
class GateStaff {
  const GateStaff({
    this.id,
    required this.name,
    required this.username,
    this.phone,
  });

  /// `gate_users.id` — dipakai untuk mencocokkan petugas di riwayat.
  final int? id;

  /// `gate_users.name` — nama yang ditampilkan, mis. "Validator 1".
  final String name;

  /// `gate_users.username` — akun yang dipakai login, mis. "gate1".
  final String username;

  /// `gate_users.phone` — opsional, boleh kosong.
  final String? phone;

  /// Nama siap tampil: jatuh ke username bila kolom name kosong.
  String get displayName =>
      name.isNotEmpty ? name : (username.isNotEmpty ? username : '');

  /// Inisial avatar dua huruf: "Validator 1" → "V1", "wisma" → "WI".
  ///
  /// Kosong bila nama tidak diketahui — pemanggil boleh menampilkan lingkaran
  /// kosong, lebih baik daripada inisial karangan.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final single = parts.first;
      return (single.length >= 2 ? single.substring(0, 2) : single)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Baca petugas dari balikan API maupun dari cache Hive (bentuknya sama).
  factory GateStaff.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final phone = (json['phone'] as String?)?.trim();

    return GateStaff(
      id: rawId is int ? rawId : int.tryParse('${rawId ?? ''}'),
      name: (json['name'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      phone: (phone == null || phone.isEmpty) ? null : phone,
    );
  }

  /// Bentuk yang disimpan ke Hive.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'phone': phone,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GateStaff &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          phone == other.phone;

  @override
  int get hashCode => Object.hash(runtimeType, id, name, username, phone);

  @override
  String toString() => 'GateStaff($username, $name)';
}
