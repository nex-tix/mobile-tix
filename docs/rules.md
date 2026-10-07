# Universal Flutter Mobile Development Rules & Standards

Dokumen aturan ini dirancang sebagai standar pengembangan universal untuk seluruh jenis aplikasi mobile (Fintech, Banking, Edukasi, E-Commerce, POS, Custom Enterprise App) berbasis Flutter dengan fondasi arsitektur **Mobnas / Feature-Driven Clean Pattern**.

---

## 1. Prinsip Utama (Core Engineering Principles)

1. **Feature-Driven Modular Architecture**:
   - Pisahkan kode menjadi dua layer utama: `lib/core/` (komponen bersama, service, utilitas) dan `lib/features/` (modul fitur bisnis).
   - Setiap fitur bersifat modular dan *self-contained* (memiliki BLoC/Cubit, data/DAO/Model, dan UI-nya sendiri).
2. **Strict Separation of Concerns (BLoC / Cubit Pattern)**:
   - UI (`StatelessWidget`/`StatefulWidget`) hanya bertugas merender tampilan berdasarkan state dan mengirim event/pemicu method.
   - Semua logika bisnis, manipulasi data, dan orkestrasi API berada di layer BLoC/Cubit atau Repository.
3. **Non-Blocking UI / UX Excellence**:
   - Jangan gunakan modal dialog yang memblokir layar untuk aksi ringan (seperti salin nomor rekening/VA, token, notifikasi sukses ringan). Gunakan **`showSnackBar` (Top Floating Notification)**.
   - Gunakan dialog modal konfirmasi hanya untuk aksi destruktif atau penting (Logout, Hapus Data, Konfirmasi Pembayaran).
4. **Proactive Session & Resilient Auth**:
   - Selalu implementasikan penjadwalan pembaruan token otomatis sebelum masa berlaku habis (*proactive token refresh*).
   - Sediakan peringatan interaktif sebelum sesi kedaluwarsa saat pengguna idle (*idle timeout warning*).
   - Terapkan mekanisme *transparent auto-retry* jika request API menerima status `401 Unauthorized`.
5. **Universal Security & Data Integrity**:
   - Semua request HTTP wajib memiliki timestamp valid, request payload hashing (SHA256), dan signature authentication (HMAC-SHA256).
   - Data sensitif wajib dienkripsi (AES-CBC PKCS7) di sisi transmisi dan penyimpanan lokal (Encrypted DAO).
6. **Strict Internationalization (i18n)**:
   - Dilarang keras melakukan hardcode teks pada file UI. Seluruh string harus diambil via `tr('key')` dan terdaftar di file lokalisasi multi-bahasa (`id` dan `en`).

---

## 2. Standar Komponen UI & Desain

### A. Notifikasi & Feedback Ringan (Top Floating SnackBar)
- **Fungsi**: `showSnackBar(context, message, {backgroundColor, icon, duration})`
- **Aturan**:
  - Tampil melayang di bagian atas layar (di bawah status bar/notch).
  - Otomatis menghapus (*dismiss*) notifikasi sebelumnya jika ada notifikasi baru masuk.
  - **Palet Warna Standar**:
    - **Sukses**: `AppColors.green` atau `context.primary` (`Icons.check_circle_outline_rounded`).
    - **Peringatan**: `AppColors.warning` (`Icons.warning_amber_rounded`).
    - **Error / Gagal**: `AppColors.danger` (`Icons.error_outline_rounded`).
  - **Durasi**: Standar 3 detik (5 detik untuk peringatan kritis).

### B. Widget Salin Teks (`TextCopyable`)
- Gunakan untuk semua data yang dapat disalin pengguna (Nomor Rekening, VA, Kode Referral, Token, ID Transaksi).
- Fitur wajib: Menampilkan ikon copy, menyalin ke clipboard, masking data sensitif (`hidden: true -> **********`), dan memicu Top SnackBar hijau.

### C. Dialog Konfirmasi vs Bottom Sheet
- **Dialog Modal (`DialogUtil().show`)**: Hanya untuk konfirmasi aksi penting dengan tombol OK/Batal yang jelas.
- **Bottom Sheet Modal (`showModalBottomSheet`)**: Untuk formulir input, pilihan filter, opsi menu, atau detail rincian transaksi dengan sudut atas melengkung (`BorderRadius.vertical(top: Radius.circular(AppLayout.radius))`).

### D. Segmented Control & Tab Bar
- Gunakan desain **Segmented Pill**:
  - Container tinggi `46px`, `padding: 4px`, latar netral lembut (misal: `#F1F5F9` pada tema terang).
  - Pill aktif berlatar kartu putih dengan soft shadow (`blurRadius: 4, offset: Offset(0, 1)`).
  - Teks aktif tebal dan kontras tinggi (`FontWeight.w700`).
  - Pastikan `dividerColor: Colors.transparent` pada `TabBar`.

---

## 3. Standar Autentikasi, Sesi, & Manajemen Token

### A. Proactive Token Refresh
1. Simpan token JWT melalui DAO lokal terenkripsi (`TokenJWTDao`).
2. Baca klaim kedaluwarsa (`exp`) menggunakan utility JWT (`JwtUtil`).
3. Jadwalkan refresh token secara proaktif **30–60 detik sebelum token kedaluwarsa**.
4. Panggil endpoint refresh menggunakan token lama yang masih valid, lalu perbarui state di BLoC dan DAO tanpa menghentikan aktivitas pengguna.

### B. Auto Logout & Peringatan Inaktivitas (Idle Timer)
1. Pasang observer sentuhan layar pada root navigator (`AutoLogoutObserver`).
2. Jika pengguna idle (default 5 menit tanpa interaksi):
   - **1 Menit Sebelum Habis**: Tampilkan dialog interaktif: *"Sesi Anda akan segera berakhir karena tidak ada aktivitas. Apakah Anda ingin tetap masuk atau keluar?"*
   - Opsi **[Tetap Masuk]**: Reset timer idle, perpanjang token ke server, dan tampilkan snackbar hijau.
   - Opsi **[Keluar]**: Logout aman dan bersihkan data sesi.
   - **Jika Diabaikan**: Tutup dialog, jalankan logout otomatis, arahkan ke Login Screen, dan tampilkan notifikasi top merah (*"Sesi Anda telah berakhir"*).

---

## 4. Standar Networking & Protokol Keamanan

1. **Konfigurasi Lingkungan (`.env`)**:
   - Selalu sediakan variabel: `BASE_URL`, `IS_NEED_ENCRYPT`, `SECRET_KEY`, `IV`, `SIGNATURE`.
2. **Standar Headers API**:
   - `CHANNEL-CD`: `"01"`
   - `Accept`: `"application/json"`
   - `Accept-Language`: Sesuai locale aktif (`id` atau `en`)
   - `Authorization`: `"Bearer <token>"` (jika request butuh otentikasi)
   - `X-TIMESTAMP`: ISO 8601 dengan offset zona waktu (`yyyy-MM-dd'T'HH:mm:ss+08:00`)
   - `X-SIGNATURE`: HMAC-SHA256 dari `METHOD|ENDPOINT|[TOKEN]|HASHED_BODY|TIMESTAMP`
3. **Mekanisme Retry 401**:
   - Jika menerima HTTP 401 saat memanggil API bisnis, `ApiService` wajib mencoba 1x auto-refresh token. Jika refresh berhasil, request diulang transparan; jika gagal, baru lakukan logout.

---

## 5. Standar Lokalisasi (i18n)

1. **Folder Bahasa**:
   - `lib/features/config/lang/id/` (Bahasa Indonesia)
   - `lib/features/config/lang/en/` (Bahasa Inggris)
2. **Pemisahan Modular**:
   - Pisahkan berkas translasi per fitur / komponen (misal: `auth.dart`, `transaction.dart`, `widgets/widget_text_copyable.dart`).
3. **Registrasi Prefix**:
   - Gunakan fungsi pembantu `_prefixKeys(map, 'prefix_name')` di `lang_id.dart` dan `lang_en.dart`.
4. **Penggunaan di Kode**:
   - `tr('auth.login')`
   - Dinamis: `tr('widget.text_copyable.copied', args: {'copied': text})`

---

## 6. Standar Penamaan Berkas & Struktur Kode

| Elemen | Format | Contoh |
| :--- | :--- | :--- |
| **Berkas & Direktori** | `snake_case.dart` | `payment_screen.dart`, `token_refresh_service.dart` |
| **Class & Widget** | `PascalCase` | `PaymentScreen`, `TokenRefreshService` |
| **Fungsi & Variabel** | `camelCase` | `fetchProfile()`, `isSessionActive` |
| **BLoC / Cubit Class** | `<Feature>Bloc` / `<Feature>Cubit` | `AuthBloc`, `AccountCubit` |
| **BLoC Event Class** | `<Action><Feature>Event` | `FetchTransactionsEvent` |
| **BLoC State Class** | `<Feature>State` | `AuthState`, `AccountState` |
| **Data Access Object (DAO)**| `<Feature>Dao` | `TokenJWTDao`, `UserDao` |
| **Model Data** | `<Feature>Model` | `TransactionModel`, `UserModel` |
| **Router Class** | `<Feature>Router` | `AuthRouter`, `PaymentRouter` |

---

## 7. Checklist Kualitas Sebelum Rilis / Commit

- [ ] **Clean Analysis**: Jalankan `fvm flutter analyze` dan pastikan **0 issue / error**.
- [ ] **No Hardcoded Strings**: Semua string tampilan menggunakan `tr(...)`.
- [ ] **No Hardcoded Colors**: Semua warna menggunakan `AppColors` atau `context.primary`/`context.secondary`.
- [ ] **No Hardcoded Dimensions**: Margin, padding, dan radius menggunakan token `AppLayout`.
- [ ] **Mounted Context Safety**: Setiap pemanggilan `Navigator` atau `context.read` setelah operasi `async` harus dilindungi dengan `if (context.mounted)`.
- [ ] **Safe Logout**: Setiap logout membersihkan DAO, membatalkan timer aktif, dan mereset BLoC state.
