# Mobile Tix — Gate Validation & Check-in Mobile App

Aplikasi mobile berbasis Flutter untuk validasi tiket, check-in pengunjung, dan pemantauan statistik gate secara real-time maupun offline.

---

## 🚀 Fitur Utama

- **Pindaian & Validasi Tiket**:
  - Validasi tiket QR/Barcode dengan 6 status verdict: `VALID`, `ALREADY_USED`, `EXPIRED`, `NOT_YET_VALID` (belum masuk masa berlaku), `NOT_FOUND`, `CANCELLED`.
  - Dukungan dua mode operasi: **Mode Cek** (hanya periksa) dan **Mode Check-in** (validasi + check-in).
  - Umpan balik audio (beep) dan getar haptic otomatis saat pindaian berhasil maupun ditolak.
- **Offline First & Auto-Sync**:
  - Antrean offline terenkripsi via Hive (`OfflineQueueDAO`) saat koneksi jaringan terputus.
  - Sinkronisasi otomatis begitu koneksi internet pulih tanpa risiko tiket dobel (*deduplikasi terproteksi*).
- **Dashboard Statistik Terpadu**:
  - Metrik pengunjung hari ini (`today`) dan bulan ini (`month`).
  - Breakdown gate aktif dan tipe pengunjung.
  - Shimmer loading state dan pembaruan reaktif via `RefreshIndicator`.
- **Riwayat Pindaian Lengkap**:
  - Paginasi gulir tak hingga (*infinite scroll*) dengan deduplikasi baris.
  - Penyaringan dinamis berdasarkan gate, status tiket, dan tanggal.
- **Keamanan Enterprise**:
  - Autentikasi berbasis JWT dengan penyimpanan Hive terenkripsi AES-256 (`TokenJwtDAO`).
  - Request signing HMAC-SHA256 (`X-SIGNATURE`), auto-inject timestamp & channel code.
  - Auto token refresh saat HTTP 401 dan auto logout saat sesi tidak aktif.
- **Multibahasa & Tema**:
  - Dukungan Bahasa Indonesia (id) dan English (en) via `EasyLocalization`.
  - Mode gelap (dark mode default) dengan palet warna modern.

---

## 🏗️ Arsitektur Aplikasi

Aplikasi dibangun dengan arsitektur bersih (*Clean Architecture*) berbasis **BLoC / Cubit**:

```
lib/
├── core/
│   ├── bloc/          # AuthBloc, TokenJwtCubit, ThemeCubit, LanguageCubit
│   ├── config/        # EnvConfig, ApiEndpoints
│   ├── constants/     # TicketStatus, AppIcons
│   ├── data/
│   │   ├── dao/       # TokenJwtDAO, CheckpointDAO, OfflineQueueDAO (Hive)
│   │   └── repositories/ # AuthRepository, CheckpointRepository, DashboardRepository
│   ├── services/      # ApiService (Dio), MockApiAdapter, EncryptionService, AudioFeedbackService
│   └── ui/            # Reusable UI widgets & Snackbars
├── features/
│   ├── auth/          # Login, Profile, Session management
│   ├── checkpoint/    # Gate selection & Checkpoint picker
│   ├── dashboard/     # DashboardScreen, DashboardCubit, DashboardSkeleton
│   ├── history/       # HistoryScreen, HistoryCubit, HistorySkeleton
│   └── scanner/       # ScannerScreen, ScannerCubit, TicketRepository
└── shared/
    └── widgets/       # ShimmerLoading, ErrorViews
```

---

## 🛠️ Panduan Memulai (Setup)

### 1. Prasyarat
- Flutter SDK (direkomendasikan via [FVM](https://fvm.app/) — Flutter `3.47.x`)
- Dart SDK `^3.13.4`

### 2. Konfigurasi Lingkungan (.env)
Salin `.env.example` ke `.env`:

```bash
cp .env.example .env
```

Isi konfigurasi sesuai kebutuhan:
```env
BASE_URL=https://secureapi.pandemenulis.com/tiket/api
API_TIMEOUT=30000
USE_MOCK_API=false
IS_NEED_ENCRYPT=true
SECRET_KEY=your-32-char-secret-key-12345678
IV=1234567890123456
SIGNATURE_SECRET=your-signature-secret-here-changeme
CHANNEL_CD=01
DEFAULT_LANGUAGE=id
ENABLE_OFFLINE_QUEUE=true
ENABLE_AUTO_LOGOUT=true
ENABLE_AUDIO_FEEDBACK=true
```

> **Catatan Pengujian (Mock Mode)**:  
> Secara default, `USE_MOCK_API=true` mengaktifkan `MockApiAdapter` yang mensimulasikan seluruh 8 endpoint API tanpa membutuhkan server backend aktif. Saat backend riil siap, cukup ubah `USE_MOCK_API=false`.

### 3. Install Dependensi
```bash
fvm flutter pub get
```

### 4. Menjalankan Pengujian (Quality Gate)
```bash
# Analisis statis kode (Linter)
fvm flutter analyze

# Menjalankan seluruh rangkaian tes (100% Pass)
fvm flutter test
```

### 5. Menjalankan Aplikasi
```bash
fvm flutter run
```

---

## 🔌 Daftar 8 Endpoint API (PRD Terintegrasi)

1. `POST /login` — Autentikasi petugas gate & penerbitan token JWT.
2. `POST /logout` — Invalidation sesi token di server.
3. `GET /me` — Data profil dan hak akses petugas yang sedang aktif.
4. `GET /checkpoints` — Daftar gerbang/gate yang tersedia.
5. `POST /ticket/check` — Mode periksa keabsahan tiket tanpa menulis check-in.
6. `POST /ticket/validate-and-checkin` — Mode validasi sekaligus pencatatan check-in tiket.
7. `GET /dashboard/summary` — Statistik ringkasan pindaian harian & bulanan.
8. `GET /ticket/history` — Riwayat riil pindaian dengan filter terpaginasi.
