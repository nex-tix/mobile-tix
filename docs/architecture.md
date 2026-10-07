# Universal Flutter Mobile Architecture Blueprint

Dokumen ini adalah cetak biru arsitektur teknis (*technical architecture blueprint*) universal untuk membangun aplikasi mobile berskala enterprise menggunakan **Flutter** dengan pola **Feature-Driven Clean Architecture** (fondasi Mobnas).

Dokumen ini dirancang agar dapat diterapkan secara langsung pada berbagai jenis domain project:
- 🏦 **Fintech & Digital Banking** (Multi-account, transaksi, mutasi, VA, e-wallet)
- 🏫 **Edukasi & Sekolah / Kampus** (Portal siswa/orang tua, raport, tagihan SPP, presensi)
- 🛒 **E-Commerce & Retail** (Katalog produk, checkout, keranjang, payment gateway)
- 🧾 **Point of Sale (POS) & Kolektor** (Kasir kas, printer thermal, offline sync, invoice)
- 🏢 **Enterprise Internal Apps** (Approval workflow, attendance, employee self-service)

---

## 1. Diagram Arsitektur Berlapis (Layered Architecture)

Arsitektur aplikasi memisahkan kode ke dalam lapisan-lapisan independen (*Separation of Concerns*):

```
┌───────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                              │
│   ┌───────────────────────────────────────────────────────────────────┐   │
│   │  Screens & Sections (Stateful/Stateless Widgets)                  │   │
│   │  Reusable Widgets (TextCopyable, SegmentedControl, Cards, Forms)  │   │
│   │  Modals & Alerts (Top SnackBar, Bottom Sheet, Confirm Dialog)     │   │
│   └─────────────────────────────────┬─────────────────────────────────┘   │
└─────────────────────────────────────┼─────────────────────────────────────┘
                                      │ (Dispatches Events / Calls Methods)
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER (BLoC / CUBIT)                  │
│   ┌───────────────────────────────────────────────────────────────────┐   │
│   │  Feature Blocs & Cubits (Emits UI States)                         │   │
│   │  Global Cubits (TokenJWTCubit, ThemeCubit, LanguageCubit)         │   │
│   └─────────────────────────────────┬─────────────────────────────────┘   │
└─────────────────────────────────────┼─────────────────────────────────────┘
                                      │ (Invokes Repositories & Services)
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                          DATA & REPOSITORY LAYER                          │
│   ┌───────────────────────────────┐   ┌───────────────────────────────┐   │
│   │     Repository Implements     │   │     Data Models & Mappers     │   │
│   └───────────────┬───────────────┘   └───────────────┬───────────────┘   │
│                   │                                   │                   │
│         ┌─────────┴─────────┐               ┌─────────┴─────────┐         │
│         ▼                   ▼               ▼                   ▼         │
│   ┌───────────────┐   ┌───────────┐   ┌───────────┐   ┌───────────────┐   │
│   │  Remote API   │   │ Encrypted │   │ Local DAO │   │ Token/Session │   │
│   │ (ApiService)  │   │ Security  │   │ (Storage) │   │   Manager     │   │
│   └───────────────┘   └───────────┘   └───────────┘   └───────────────┘   │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Struktur Direktori Universal (Directory Tree)

```
lib/
├── main.dart                          # Entry point, Firebase, Provider setup, App bootstrap
│
├── core/                              # SHARED CORE ENGINE (Digunakan lintas fitur)
│   ├── bloc/                          # Global BLoCs & Cubits
│   │   ├── auth/token_jwt/            # Auth state, token holder, logout triggers
│   │   ├── language/                  # Active language state & switcher
│   │   └── theme/                     # AppColors, AppLayout, dynamic theme state
│   ├── config/                        # Global App Configuration
│   │   ├── constants/                 # AppConfig, AppEndpoints, AppInfo
│   │   ├── lang/                      # Core i18n base maps (id/ dan en/)
│   │   └── routes/                    # Global route observers & app router
│   ├── data/                          # Core Data Sources
│   │   ├── dao/                       # TokenJWTDao, UsernameDao, BiometricSetupDao
│   │   └── models/                    # ApiResponseModel, Base models
│   ├── services/                      # Core Infrastructure Services
│   │   ├── api_service.dart           # Dio HTTP client, interceptors, 401 retry
│   │   ├── encryption_service.dart    # AES-CBC PKCS7 encryption/decryption
│   │   ├── signature_service.dart     # HMAC-SHA256 request signer
│   │   ├── token_refresh_service.dart # Background proactive JWT renewal timer
│   │   ├── auto_logout_service.dart   # Inactivity idle tracker & warning prompt
│   │   └── auto_logout_observer.dart  # Global touch & navigation observer
│   ├── ui/                            # Core Shared UI Elements
│   │   ├── screens/global/            # Splash, PIN lock, Camera overlay, Biometric
│   │   └── widgets/                   # App Bar, Button, Input Form, Shimmer, Layout
│   └── utils/                         # Pure Utilities
│       ├── color_extension.dart       # Contrast color, brightness calculations
│       ├── dialog_util.dart           # Global modal dialog manager
│       ├── jwt_util.dart              # JWT claim extraction & expiry calculation
│       ├── loading_util.dart          # Loading overlay indicator
│       └── text_utils.dart            # Currency, date, and string formatting
│
└── features/                          # BUSINESS FEATURE MODULES (Modular per domain)
    ├── bloc/                          # Feature-specific BLoCs / Cubits
    ├── config/                        # Feature-specific configurations & routes
    │   ├── lang/                      # Feature i18n maps (id/ dan en/)
    │   └── routes/                    # Feature route declarations
    ├── data/                          # Feature Data Layer
    │   ├── dao/                       # Feature local DAOs (e.g. SavedAccountsDao)
    │   └── models/                    # Feature Data Models (JSON serializable)
    ├── repository/                    # Repository interfaces & implementations
    └── ui/                            # Feature Presentation Layer
        ├── screens/                   # Main screens (grouped by sub-feature)
        │   ├── auth/                  # Login, Register, Forgot Password
        │   ├── home/                  # Dashboard, Header, Balance summary
        │   ├── payment/               # Payment, VA instruction, History
        │   └── profile/               # User profile, Switch account, Settings
        └── widgets/                   # Reusable feature-level widgets
            ├── modal/                 # snackbar_top.dart (Top Floating Overlay)
            ├── text/                  # text_copyable.dart (Clipboard copyable widget)
            └── cards/                 # Feature custom cards & list items
```

---

## 3. Alur End-to-End Utama (Core Workflows)

### A. Alur Proactive Token Refresh (Zero Session Interruption)
```
User Login / App Start
         │
         ▼
TokenJWTCubit.updateToken(token)
         │
         ▼
TokenRefreshService.scheduleNextRefresh(token)
         │
         ├─► Hitung sisa waktu token via JwtUtil.timeRemaining(token)
         └─► Set Timer pada (Waktu Kedaluwarsa - 45 detik)
         │
         ▼ (Saat Timer Terpicu - Token Lama Masih Aktif)
ApiService.refreshToken(currentToken)
         │
         ├─► Sukses ──► Simpan token baru ke TokenJWTDao, Cubit, & SavedAccountsDao
         │              └─► Jadwalkan siklus perpanjangan berikutnya secara otomatis
         │
         └─► Gagal  ──► Sesi dibiarkan berjalan hingga idle timer atau 401 retry
```

### B. Alur Peringatan Inaktivitas (Idle Session Timeout)
```
User Tidak Menyentuh Layar (Idle)
         │
         ▼
[Durasi Timeout - 1 Menit] ──► Tampilkan Dialog Konfirmasi Interaktif
                                ├── [Tetap Masuk] ──► Reset Idle Timer
                                │                     ├─► Refresh Token ke Server
                                │                     └─► Tampilkan Top SnackBar Hijau
                                │
                                └── [Keluar]      ──► Logout Aman ──► Redirect ke Login
         │
         ▼ (Jika Pengguna Tidak Menekan Tombol Hingga Timeout Habis)
[Timeout Habis (0 Detik)] ────► Tutup Dialog Modal (jika terbuka)
                                ├─► Bersihkan token di DAO & BLoC
                                ├─► Redirect ke Halaman Login
                                └─► Tampilkan Top SnackBar Merah ("Sesi Anda telah berakhir")
```

### C. Alur Request Signing & Enkripsi (Network Security Pipeline)
```
HTTP Request Dibuat
         │
         ├──► 1. Generate Timestamp: "yyyy-MM-ddTHH:mm:ss+08:00"
         ├──► 2. Hash Payload Body: SHA256(JSON(body))
         ├──► 3. Build Base String: METHOD | PATH | TOKEN_NO_BEARER | HASHED_BODY | TIMESTAMP
         ├──► 4. Sign HMAC-SHA256: Base64(HMAC(BaseString, SIGNATURE_SECRET))
         │
         ▼
Kirim via Dio (Headers: CHANNEL-CD, X-TIMESTAMP, X-SIGNATURE, Authorization)
         │
         ▼
Terima Response
         ├──► Status 200: Dekripsi AES-CBC PKCS7 (jika respons terenkripsi) ──► Parse Model
         ├──► Status 401: Coba 1x Auto-Refresh Token ──► Ulangi Request Transparan
         └──► Status Error: Tampilkan Dialog Error / Tangani di BLoC State
```

---

## 4. Panduan Implementasi Project Baru (Step-by-Step Blueprint)

Saat membuat project baru dengan standar ini, ikuti urutan berikut:

1. **Step 1: Setup Dependencies (`pubspec.yaml`)**
   - Pastikan dependency utama terpasang: `flutter_bloc`, `dio`, `crypto`, `steel_crypt`, `jwt_decode` (atau custom `jwt_util`), `shared_preferences`, `intl`, `iconsax_flutter`, `google_fonts`, `flutter_svg`.

2. **Step 2: Setup Environment (`.env`)**
   - Konfigurasi `BASE_URL`, `IS_NEED_ENCRYPT`, `SECRET_KEY`, `IV`, `SIGNATURE`.

3. **Step 3: Setup Core Services**
   - Pasang `api_service.dart`, `encryption_service.dart`, `signature_service.dart`, `token_refresh_service.dart`, dan `auto_logout_service.dart`.

4. **Step 4: Setup UI & Theme Engine**
   - Terapkan `AppColors`, `AppLayout`, `snackbar_top.dart`, dan `text_copyable.dart`.

5. **Step 5: Setup Global Routing & Observers di `main.dart`**
   - Daftarkan `AppRouteObserver` dan `AutoLogoutObserver` pada `navigatorObservers`.
   - Hubungkan `GlobalKey<NavigatorState>` ke `DialogUtil` dan `AutoLogoutService`.

6. **Step 6: Implementasi Fitur Modular**
   - Buat fitur baru di dalam `lib/features/<nama_fitur>/` dengan struktur: `bloc/`, `data/`, `repository/`, `ui/screens/`, `ui/widgets/`.
