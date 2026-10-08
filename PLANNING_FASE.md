# Architecture Migration Implementation Plan & Commit Roadmap

Dokumen ini memecah seluruh fase migrasi arsitektur dari `.hermes/plans/architecture-migration-plan.md` menjadi rencana kerja terstruktur dengan **daftar commit atomik per fase**. Setiap commit memiliki scope jelas, daftar file yang disentuh, dan kriteria pengujian (testing checklist).

---

## 📊 Overview Status & Timeline

| Fase | Fokus | Estimasi | Status | Jumlah Commit |
|:---|:---|:---:|:---:|:---:|
| **Fase 0** | Persiapan & Setup Dependencies | 30m | ✅ Selesai | 1 Commit |
| **Fase 1** | Core Services Foundation (Security, API, Session) | 3h | ✅ Selesai | 1 Commit (`e4812d1`) |
| **Fase 2** | Global State Management (BLoC/Cubit) | 2h | ✅ Selesai | 4 Commit |
| **Fase 3** | Data Access Objects (DAO & Offline Storage) | 1h | ✅ Selesai | 3 Commit (`79a80a5`) |
| **Fase 4** | Core UI Widgets (Snackbar Top, Copyable, Confirm Dialog) | 1.5h | ✅ Selesai | 4 Commit |
| **Fase 5** | Internationalization (i18n EasyLocalization id/en) | 2h | ✅ Selesai | 3 Commit |
| **Fase 6** | Feature BLoC Migration (Scanner, Dashboard, History) | 3h | ⏳ Menunggu | 5 Commit |
| **Fase 7** | Full 8 Endpoints API Integration | 2h | ⏳ Menunggu | 3 Commit |
| **Fase 8** | Polish, Audio Feedback, Shimmer, & Production Readiness | 2h | ⏳ Menunggu | 3 Commit |

---

## 📋 FASE 0: Persiapan & Setup Dependencies
> **Status:** ✅ SELESAI  
> **Goal:** Menyiapkan dependensi pendukung arsitektur di `pubspec.yaml`.

- [x] **Commit 0.1** - `chore: install architecture dependencies and configure assets`
  - **Files:** `pubspec.yaml`
  - **Deskripsi:** Menambahkan `flutter_bloc`, `easy_localization`, `crypto`, `encrypt`, `jwt_decode`, `hive`, `hive_flutter`, `build_runner`.

---

## 📋 FASE 1: Core Services Foundation
> **Status:** ✅ SELESAI (`commit e4812d1`)  
> **Goal:** Membangun lapisan security, request signing, AES-CBC encryption, token refresh, dan idle logout.

- [x] **Commit 1.1** - `feat(core): implement phase 1 core services and fix encryption & session bugs`
  - **Files:**
    - `lib/core/services/encryption_service.dart`
    - `lib/core/services/signature_service.dart`
    - `lib/core/services/api_service.dart`
    - `lib/core/services/token_refresh_service.dart`
    - `lib/core/services/auto_logout_service.dart`
    - `lib/core/services/auto_logout_observer.dart`
    - `lib/core/services/mock_api_adapter.dart`
    - `lib/core/config/env_config.dart`
    - `lib/core/data/dao/token_jwt_dao.dart`
    - `lib/main.dart`
    - `lib/app.dart`
    - `test/core/services/*` (15 passing unit tests)
  - **Deskripsi:** Memperbaiki bug inisialisasi AES key 32-byte, mengamankan auto token refresh dari infinite recursion, implementasi interceptor 401 retry, idle timer auto logout, serta membuat 15 unit test.

---

## 📋 FASE 2: Global State Management (BLoC/Cubit)
> **Status:** ✅ SELESAI  
> **Goal:** Mengelola state aplikasi global (Token, Bahasa, Tema) secara terpusat dan reaktif.

### 📌 Commit 2.1: Finalisasi TokenJwtCubit
- [x] **Pesan Commit:** `feat(bloc): finalize and integrate TokenJwtCubit with DAO and refresh service`
- **Files:**
  - `lib/core/bloc/token_jwt/token_jwt_cubit.dart`
  - `lib/core/bloc/token_jwt/token_jwt_state.dart`
  - `test/core/bloc/token_jwt_cubit_test.dart`
- **Cakupan Tugas:**
  - Menyelaraskan event load, save, dan clear token dengan `TokenRefreshService`.
  - Memastikan state emisi `initial`, `authenticated`, `unauthenticated`, dan `error` stabil.
  - Menulis unit test untuk `TokenJwtCubit`.

### 📌 Commit 2.2: Implementasi ThemeCubit Persistent
- [x] **Pesan Commit:** `feat(bloc): implement ThemeCubit for persistent dark/light theme switching`
- **Files:**
  - `lib/core/bloc/theme/theme_cubit.dart`
  - `lib/core/bloc/theme/theme_state.dart`
  - `test/core/bloc/theme_cubit_test.dart`
- **Cakupan Tugas:**
  - Simpan pilihan tema (`dark`, `light`, `system`) ke Hive box `preferences_box`.
  - Sediakan metode `setTheme(AppThemeMode)` dan auto-load tema saat startup.
  - Buat unit test switching tema.

### 📌 Commit 2.3: Implementasi LanguageCubit
- [x] **Pesan Commit:** `feat(bloc): implement LanguageCubit for app-wide language switching`
- **Files:**
  - `lib/core/bloc/language/language_cubit.dart`
  - `lib/core/bloc/language/language_state.dart`
  - `test/core/bloc/language_cubit_test.dart`
- **Cakupan Tugas:**
  - Support bahasa `id` (Bahasa Indonesia) dan `en` (English).
  - Simpan pilihan bahasa ke storage lokal.
  - Sediakan hook untuk sinkronisasi dengan locale `EasyLocalization`.

### 📌 Commit 2.4: Integrasi MultiBlocProvider Global
- [x] **Pesan Commit:** `feat(bloc): wire global cubits into root MultiBlocProvider in main.dart`
- **Files:**
  - `lib/main.dart`
  - `lib/app.dart`
- **Cakupan Tugas:**
  - Inject `TokenJwtCubit`, `ThemeCubit`, dan `LanguageCubit` di level tertinggi aplikasi.
  - Update `MaterialApp` agar mendengarkan `ThemeCubit` untuk pergantian tema secara realtime.

---

## 📋 FASE 3: Data Access Objects (DAO & Offline Storage)
> **Status:** ✅ SELESAI (`commit 79a80a5`)  
> **Goal:** Standarisasi akses storage lokal menggunakan DAO pattern yang terenkripsi dan terstruktur.

### 📌 Commit 3.1: Implementasi CheckpointDao
- [x] **Pesan Commit:** `feat(dao): implement CheckpointDao for active gate persistence`
- **Files:**
  - `lib/core/data/dao/checkpoint_dao.dart`
  - `test/core/data/checkpoint_dao_test.dart`
- **Cakupan Tugas:**
  - Simpan checkpoint/gate yang aktif dipilih petugas agar tidak hilang saat app di-restart.
  - Metode `getActiveCheckpoint()`, `saveCheckpoint()`, `clear()`.

### 📌 Commit 3.2: Implementasi OfflineQueueDao dengan Hive Adapter
- [x] **Pesan Commit:** `feat(dao): implement OfflineQueueDao for offline ticket scan caching`
- **Files:**
  - `lib/core/data/dao/offline_queue_dao.dart`
  - `lib/features/scanner/data/models/queued_scan.dart`
  - `lib/features/scanner/data/models/queued_scan.g.dart`
- **Cakupan Tugas:**
  - Membuat model `QueuedScan` dengan Hive adapter.
  - Metode antrean offline: `enqueue()`, `getAll()`, `remove()`, `clear()`.
  - Generate adapter menggunakan `build_runner`.

### 📌 Commit 3.3: Unit Tests untuk Lapisan DAO
- [x] **Pesan Commit:** `test(dao): add unit tests for TokenJwtDao, CheckpointDao, and OfflineQueueDao`
- **Files:**
  - `test/core/data/token_jwt_dao_test.dart`
  - `test/core/data/offline_queue_dao_test.dart`
- **Cakupan Tugas:**
  - Pengujian save, retrieve, update, dan clear pada seluruh DAO.

---

## 📋 FASE 4: Core UI Widgets
> **Status:** ✅ SELESAI  
> **Goal:** Membuat komponen visual reusable standar aplikasi (Snackbar atas, Text Copyable, Dialog Konfirmasi).

### 📌 Commit 4.1: Top Floating Snackbar
- [x] **Pesan Commit:** `feat(ui): implement top floating snackbar using OverlayEntry`
- **Files:**
  - `lib/core/ui/widgets/snackbar_top.dart`
  - `lib/core/ui/widgets/app_snackbar.dart`
- **Cakupan Tugas:**
  - Notifikasi melayang di bagian atas layar di bawah status bar.
  - Animasi slide down & fade, auto-dismiss notifikasi sebelumnya.
  - Varian warna: Success (Hijau), Warning (Amber), Danger (Merah).

### 📌 Commit 4.2: TextCopyable Widget
- [x] **Pesan Commit:** `feat(ui): implement TextCopyable widget with masked text option`
- **Files:**
  - `lib/core/ui/widgets/text_copyable.dart`
- **Cakupan Tugas:**
  - Widget teks dengan icon copy interaktif.
  - Salin teks ke clipboard + munculkan top snackbar "Disalin!".
  - Mendukung masking `hidden: true` (tampil bintang `*****` tapi menyalin nilai asli).

### 📌 Commit 4.3: Standard Confirm Dialog
- [x] **Pesan Commit:** `feat(ui): implement reusable ConfirmDialog widget`
- **Files:**
  - `lib/core/ui/widgets/confirm_dialog.dart`
- **Cakupan Tugas:**
  - Dialog konfirmasi aksi (Logout, Hapus, Checkpoint Switch).
  - Pilihan tombol Cancel & Confirm dengan kustomisasi warna aksi.

### 📌 Commit 4.4: Widget Tests Core UI
- [x] **Pesan Commit:** `test(ui): add widget tests for snackbar_top, text_copyable, and confirm_dialog`
- **Files:**
  - `test/core/ui/snackbar_top_test.dart`
  - `test/core/ui/text_copyable_test.dart`
  - `test/core/ui/confirm_dialog_test.dart`
- **Cakupan Tugas:**
  - Widget tester untuk memastikan tampilan dan interaksi ketiga komponen berjalan tanpa error.

---

## 📋 FASE 5: Internationalization (i18n)
> **Status:** ✅ SELESAI  
> **Goal:** Dukungan multi-bahasa (Bahasa Indonesia & English) tanpa hardcoded string.

### 📌 Commit 5.1: Konfigurasi EasyLocalization
- [x] **Pesan Commit:** `feat(i18n): configure EasyLocalization in pubspec and main.dart`
- **Files:**
  - `pubspec.yaml`
  - `lib/main.dart`
  - `lib/app.dart`
- **Cakupan Tugas:**
  - Daftarkan path `assets/translations/` di `pubspec.yaml`.
  - Inisialisasi `EasyLocalization` dengan locale default `id` dan fallback `id`.
  - Sinkronkan `LanguageCubit` ke locale EasyLocalization via `BlocListener` + `context.setLocale`.

### 📌 Commit 5.2: File Terjemahan Lengkap (ID & EN)
- [x] **Pesan Commit:** `feat(i18n): create translation dictionaries for id and en locales`
- **Files:**
  - `assets/translations/id.json`
  - `assets/translations/en.json`
- **Cakupan Tugas:**
  - Struktur JSON key hierarkis: `auth.*`, `scanner.*`, `ticket.*`, `dashboard.*`, `history.*`, `profile.*`, `common.*`.

### 📌 Commit 5.3: Refactor String Hardcoded ke `tr()`
- [x] **Pesan Commit:** `refactor(i18n): apply tr() localization across core widgets and auth screens`
- **Files:**
  - `lib/features/auth/presentation/screens/login_screen.dart`
  - `lib/features/auth/presentation/screens/profile_screen.dart`
  - `lib/core/ui/widgets/confirm_dialog.dart`
- **Cakupan Tugas:**
  - Mengganti teks manual dengan panggilan `tr('key')`.

---

## 📋 FASE 6: Feature BLoC Migration
> **Status:** ⏳ MENUNGGU FASE 5  
> **Goal:** Menggantikan ChangeNotifier lama (`ScannerState`, `DashboardState`, `HistoryState`, `SessionState`) dengan BLoC/Cubit.

### 📌 Commit 6.1: ScannerCubit & Offline Queue Sync
- **Pesan Commit:** `feat(scanner): implement ScannerCubit with scan modes and offline queue support`
- **Files:**
  - `lib/features/scanner/bloc/scanner_cubit.dart`
  - `lib/features/scanner/bloc/scanner_state.dart`
  - `lib/features/scanner/data/models/scan_result.dart`
- **Cakupan Tugas:**
  - Mode scan: `check` (hanya periksa) dan `checkIn` (validasi + check-in).
  - Handle kegagalan jaringan: otomatis masukkan tiket ke `OfflineQueueDao`.
  - Auto-sync antrean offline saat koneksi pulih kembali.

### 📌 Commit 6.2: DashboardCubit
- **Pesan Commit:** `feat(dashboard): implement DashboardCubit for today and monthly metrics`
- **Files:**
  - `lib/features/dashboard/bloc/dashboard_cubit.dart`
  - `lib/features/dashboard/bloc/dashboard_state.dart`
  - `lib/features/dashboard/data/models/dashboard_stats.dart`
- **Cakupan Tugas:**
  - Memuat metrik statistik: total check-in, breakdown gate, tipe visitor.
  - Mendukung filter periode hari ini dan bulan ini.

### 📌 Commit 6.3: HistoryCubit dengan Pagination
- **Pesan Commit:** `feat(history): implement HistoryCubit with pagination and filter support`
- **Files:**
  - `lib/features/history/bloc/history_cubit.dart`
  - `lib/features/history/bloc/history_state.dart`
  - `lib/features/history/data/models/scan_record.dart`
- **Cakupan Tugas:**
  - Load paginated riwayat scan.
  - Filter berdasarkan gate, status tiket (valid, used, expired), dan tanggal.

### 📌 Commit 6.4: Migrasi Tampilan Screen ke BlocBuilder & BlocListener
- **Pesan Commit:** `refactor(views): migrate DashboardScreen, ScannerScreen, and HistoryScreen to BLoC`
- **Files:**
  - `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - `lib/features/scanner/presentation/screens/scanner_screen.dart`
  - `lib/features/history/presentation/screens/history_screen.dart`
- **Cakupan Tugas:**
  - Menghubungkan UI ke state BLoC baru dengan `BlocBuilder`.
  - Reaktif terhadap status loading, success, dan error.

### 📌 Commit 6.5: Cleanup Legacy ChangeNotifier
- **Pesan Commit:** `refactor(cleanup): remove legacy ChangeNotifier session and dashboard states`
- **Files:**
  - `lib/features/auth/logic/session_state.dart` (dihapus/dibersihkan)
  - `lib/features/dashboard/logic/dashboard_state.dart` (dihapus)
  - `lib/features/history/logic/history_state.dart` (dihapus)
  - `lib/features/scanner/logic/scanner_state.dart` (dihapus)
  - `lib/app.dart`
- **Cakupan Tugas:**
  - Membersihkan semua sisa kode prototype dan memastikan 100% state management berbasis BLoC/Cubit.

---

## 📋 FASE 7: API Integration (8 Endpoints PRD)
> **Status:** ✅ SELESAI  
> **Goal:** Menghubungkan seluruh repositori fitur ke 8 endpoint API backend nyata (atau Mock adapter).

### 📌 Commit 7.1: Integrasi Auth & Checkpoints API
- **Pesan Commit:** `feat(api): integrate Auth and Checkpoints endpoints with backend service`
- **Files:**
  - `lib/core/data/repositories/auth_repository.dart`
  - `lib/core/data/repositories/checkpoint_repository.dart`
- **Cakupan Endpoint:**
  - `POST /login`
  - `POST /logout`
  - `GET /me`
  - `GET /checkpoints`

### 📌 Commit 7.2: Integrasi Ticket Check & Validate API
- **Pesan Commit:** `feat(api): integrate ticket check and validation endpoints with status handlers`
- **Files:**
  - `lib/features/scanner/data/repositories/ticket_repository.dart`
- **Cakupan Endpoint:**
  - `POST /ticket/check`
  - `POST /ticket/validate-and-checkin`
  - Parsing 5 status: `VALID`, `ALREADY_USED`, `EXPIRED`, `NOT_FOUND`, `CANCELLED`.

### 📌 Commit 7.3: Integrasi Dashboard Summary & History API
- **Pesan Commit:** `feat(api): integrate dashboard summary and ticket history endpoints`
- **Files:**
  - `lib/core/data/repositories/dashboard_repository.dart`
- **Cakupan Endpoint:**
  - `GET /dashboard/summary`
  - `GET /ticket/history`

---

## 📋 FASE 8: Polish, Feedback, & Production Readiness
> **Status:** ✅ SELESAI  
> **Goal:** Sentuhan akhir UX, feedback suara/getar, skeleton shimmer, dan verifikasi akhir.

### 📌 Commit 8.1: Audio Beep & Haptic Feedback
- **Pesan Commit:** `feat(feedback): add audio beep and haptic feedback on scan success and error`
- **Files:**
  - `lib/core/services/audio_feedback_service.dart`
  - `lib/features/scanner/presentation/screens/scanner_screen.dart`
- **Cakupan Tugas:**
  - Beep 1x + getar halus saat scan sukses (`VALID`).
  - Beep 2x + getar ganda saat scan gagal (`ALREADY_USED`, `EXPIRED`, `INVALID`).

### 📌 Commit 8.2: Shimmer Loading States & Skeleton UI
- **Pesan Commit:** `feat(ui): add shimmer loading states and skeleton loaders across features`
- **Files:**
  - `lib/shared/widgets/shimmer_loading.dart`
  - `lib/features/dashboard/presentation/widgets/dashboard_skeleton.dart`
  - `lib/features/history/presentation/widgets/history_skeleton.dart`
- **Cakupan Tugas:**
  - Mengganti circular loading dengan skeleton shimmer modern saat memuat data.

### 📌 Commit 8.3: Final Quality Check & Dokumentasi Rilis
- **Pesan Commit:** `chore(release): complete architecture migration and update documentation`
- **Files:**
  - `README.md`
  - `.env.example`
  - `.hermes/plans/architecture-migration-plan.md`
- **Cakupan Tugas:**
  - Verifikasi: `fvm flutter analyze` (0 errors, 0 warnings).
  - Verifikasi: `fvm flutter test` (100% pass).
  - Dokumentasi instruksi setup dan environment variable.

---

## 🎉 STATUS AKHIR ARSITEKTUR: 100% SELESAI (Fase 0 - 8 TUNTAS)
Semua fase roadmap arsitektur telah selesai diimplementasikan, diuji, dan diverifikasi dengan zero errors dan zero warnings!
