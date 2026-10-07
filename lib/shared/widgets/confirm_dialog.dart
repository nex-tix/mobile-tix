// File: shared/widgets/confirm_dialog.dart
// Re-export shim.
//
// Implementasi dialog konfirmasi kini tinggal SATU di
// `lib/core/ui/widgets/confirm_dialog.dart` (Fase 4 — Core UI Widgets).
// File ini dipertahankan supaya import lama di feature (auth, checkpoint)
// tetap jalan tanpa perlu diubah, dan supaya tidak ada dua implementasi
// dialog yang bisa berbeda perilaku.

export '../../core/ui/widgets/confirm_dialog.dart';
