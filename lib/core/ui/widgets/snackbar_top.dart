// File: snackbar_top.dart
// Mekanisme notifikasi melayang di bagian ATAS layar (top floating snackbar).
//
// Kenapa overlay, bukan SnackBar bawaan Material?
// SnackBar default muncul di bawah dan bisa tertutup bottom-nav bar; notifikasi
// hasil scan (valid / sudah dipakai) harus terbaca dari posisi petugas memegang
// HP. OverlayEntry juga membebaskan kita dari ScaffoldMessenger sehingga
// notifikasi tetap bisa muncul walau layar tidak punya Scaffold.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Manajer notifikasi atas — hanya SATU notifikasi tampil pada satu waktu.
///
/// Notifikasi baru selalu menggantikan notifikasi sebelumnya (yang lama dibuang
/// seketika, yang baru beranimasi masuk), supaya layar tidak menumpuk pesan saat
/// petugas scan beruntun dengan cepat.
class SnackbarTop {
  // Konstruktor privat — kelas ini dipakai sebagai utilitas statis.
  SnackbarTop._();

  // Semua entry yang saat ini terpasang di overlay.
  static final List<OverlayEntry> _entries = <OverlayEntry>[];

  // State host milik entry terakhir — dipakai untuk menutup dari luar.
  static _SnackbarTopHostState? _current;

  /// True jika sedang ada notifikasi tampil.
  static bool get isVisible => _entries.isNotEmpty;

  /// Tampilkan [child] sebagai notifikasi melayang di atas layar.
  ///
  /// [duration] — berapa lama notifikasi bertahan sebelum menutup sendiri.
  /// Notifikasi sebelumnya selalu dibuang lebih dulu (satu pesan, satu waktu).
  static void show(
    BuildContext context, {
    required Widget child,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Buang semua notifikasi yang masih tampil — penggantian bersifat langsung
    // (tanpa animasi keluar) supaya hanya satu pesan yang pernah terlihat.
    _clearAll();

    // rootOverlay: true → menempel di overlay paling atas aplikasi, jadi
    // notifikasi tetap di atas bottom sheet / dialog.
    final overlay = Overlay.of(context, rootOverlay: true);

    // Entry dideklarasikan lebih dulu supaya closure-nya bisa merujuk dirinya
    // sendiri saat memutuskan apakah dia masih entry yang aktif.
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SnackbarTopHost(
        duration: duration,
        // Daftarkan diri sebagai host aktif hanya bila dia entry terbaru.
        onReady: (state) {
          if (_entries.isNotEmpty && identical(_entries.last, entry)) {
            _current = state;
          }
        },
        onFinished: () => _removeEntry(entry),
        child: child,
      ),
    );

    _entries.add(entry);
    overlay.insert(entry);
  }

  /// Tutup notifikasi aktif dengan animasi keluar.
  static void dismiss() {
    _current?.dismiss();
  }

  // Buang SEMUA entry dari overlay secara langsung (tanpa animasi keluar).
  //
  // Dipakai saat mengganti pesan: notifikasi lama harus hilang seketika agar
  // hanya satu pesan yang pernah terlihat di layar.
  static void _clearAll() {
    // Salin daftar dulu karena remove() bisa memicu callback yang memodifikasi
    // _entries saat iterasi.
    for (final entry in List<OverlayEntry>.from(_entries)) {
      entry.remove();
    }
    _entries.clear();
    _current = null;
  }

  // Buang satu entry setelah host-nya selesai beranimasi keluar.
  static void _removeEntry(OverlayEntry entry) {
    entry.remove();
    _entries.remove(entry);

    // Tidak ada notifikasi tersisa → bersihkan referensi host aktif.
    // (Cukup aman karena show() selalu membuang entry lama secara langsung,
    // jadi paling banyak satu host yang beranimasi keluar pada satu waktu.)
    if (_entries.isEmpty) {
      _current = null;
    }
  }
}

/// Host stateful di dalam overlay: mengurus animasi masuk/keluar + auto-dismiss.
///
/// Dipisah dari [SnackbarTop] karena animasi butuh AnimationController yang
/// terikat ke lifecycle widget (dibuat saat tampil, dibuang saat hilang).
class _SnackbarTopHost extends StatefulWidget {
  const _SnackbarTopHost({
    required this.child,
    required this.duration,
    required this.onFinished,
    this.onReady,
  });

  // Isi notifikasi (kartu dari AppSnackbar).
  final Widget child;

  // Lama notifikasi bertahan di layar.
  final Duration duration;

  // Dipanggil setelah animasi keluar selesai — entry siap dibuang.
  final VoidCallback onFinished;

  // Dipanggil saat state siap, supaya SnackbarTop bisa menutup notifikasi ini
  // dari luar tanpa memakai GlobalKey.
  final void Function(_SnackbarTopHostState state)? onReady;

  @override
  State<_SnackbarTopHost> createState() => _SnackbarTopHostState();
}

class _SnackbarTopHostState extends State<_SnackbarTopHost>
    with SingleTickerProviderStateMixin {
  // Controller animasi slide + fade (masuk lebih lambat dari keluar).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSpacing.base,
    reverseDuration: AppSpacing.fast,
  );

  // Slide dari atas (-1.2 panjang kartu) turun ke posisi normal.
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  // Timer auto-dismiss.
  Timer? _timer;

  // Guard supaya proses keluar tidak berjalan dua kali (timer + tap manual).
  bool _closing = false;

  // Referensi ke entry pemilik host ini, dipakai SnackbarTop saat cleanup.
  OverlayEntry? entryRef;

  @override
  void initState() {
    super.initState();
    // Animasi masuk, lalu jadwalkan tutup otomatis.
    _controller.forward();
    _timer = Timer(widget.duration, dismiss);
    // Laporkan state ke SnackbarTop supaya bisa ditutup dari luar.
    widget.onReady?.call(this);
  }

  /// Tutup notifikasi: animasi keluar dulu, baru laporkan selesai.
  Future<void> dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();

    await _controller.reverse();
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SlideTransition(
              position: _offset,
              child: FadeTransition(
                opacity: _controller,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
