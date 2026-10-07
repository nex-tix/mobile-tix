# DESIGN-SYSTEM.md — Uluwatu Kecak Gate Validator

Dokumen rekaman arsitektur dan sistem visual aplikasi Mobile Ticket Validator yang telah diimplementasikan berdasarkan spesifikasi dan mockup pada folder `newDesign/` dengan penyesuaian palet warna baru.

---

## 1. Konsep & Identitas Desain

Aplikasi mengusung arah visual **Utilitarian Minimalist** bertema laut senja & tebing Uluwatu:
- **Karakter Lapangan (Field Utility):** Didesain khusus untuk pemindaian tiket luar ruangan saat senja hingga malam hari di amphitheater Pura Uluwatu.
- **Dark Teal Canvas Substrate (`#2A363B`):** Menggunakan latar belakang dark teal pekat (`#2A363B`) di seluruh kanvas untuk kenyamanan visual petugas dan mengurangi kelelahan mata.
- **Primary Deep Red (`#CF4647`):** Menjadi warna aksen aksi utama (Login CTA, Scan center button, reticle laser viewfinder, badge "Already Used" / "Rejected", filter aktif).
- **Secondary Gold (`#F5D061`) & Off-White (`#F8F6F6`):**
  - **Gold (`#F5D061`):** Aksen seleksi aktif (active tab pills, outline checkpoint terpilih, bar puncak jam sibuk/hourly strip, badge kedaluwarsa).
  - **Off-White (`#F8F6F6`):** Tipografi utama berdaya kontras tinggi dan tajam di atas latar dark teal.
- **High-Impact Status Signal:** Hasil pemindaian (Valid vs Already Used / Refused) hadir dengan badge status solid berukuran besar dan informasi kontras tinggi sehingga langsung terbaca jelas dari jarak satu lengan.
- **Clean Flat Buttons (No Glow):** Tombol-tombol menggunakan bentuk solid dan tegas dengan border rapi tanpa efek bayangan glow yang mengaburkan elemen.
- **Thumb-Zone Prioritization:** Semua tombol aksi utama ditempatkan di 40% area bawah layar agar mudah dioperasikan dengan satu tangan.

---

## 2. Palet Warna (Color Tokens)

Implementasi warna dikemas di dalam `AppColors` (`ThemeExtension`):

| Token | Nilai Hex | Peran & Penggunaan |
|---|---|---|
| `ground` (Dark Teal) | `#2A363B` | Latar belakang utama seluruh layar aplikasi |
| `surface` (Deep Teal) | `#212B2F` | Permukaan kartu (card), modal sheet, dialog |
| `surfaceAlt` (Elevated Teal) | `#334147` | Kontainer sekunder, track input & segmented control |
| `surfaceField` | `#182023` | Area kamera / viewfinder scanner |
| `outline` | `#3E4E55` | Garis pembatas terstruktur tipis |
| `primary` (Deep Red) | `#CF4647` | Tombol CTA utama (Login, Gate, Scan), laser reticle |
| `primaryPressed` | `#B83A3B` | Aksen gradien & state tombol ditekan |
| `secondary` (Gold) | `#F5D061` | Highlight seleksi, radio indicator aktif, puncak grafik |
| `secondary` (Off-White) | `#F8F6F6` | Teks judul utama & label kontras tinggi |
| `valid` (Emerald) | `#2ECC71` | Status tiket valid, online indicator |
| `used` (Deep Red) | `#CF4647` | Status tiket already used / ditolak |
| `expired` (Gold) | `#F5D061` | Status tiket kedaluwarsa / warning |
| `ink` (Text) | `#F8F6F6` | Tipografi primer (off-white) |
| `inkMuted` | `#A3B1B7` | Tipografi sekunder, deskripsi, placeholder |

---

## 3. Komponen Layar yang Diterapkan

### 1. Login Screen (`1._login`)
- Logo `logo.png` diperbesar (124x124 px di Login, 148x148 px di Splash) agar terlihat sangat jelas dan menonjol, disertai teks "Gate Validator".
- Form username & password dengan container `#212B2F`, border `#3E4E55`, gold focus outline (`#F5D061`), dan ikon sandi interaktif.
- Tombol "Login" bergradien Deep Red (`#CF4647` ke `#B83A3B`) bersih tanpa efek glow, dengan teks `#F8F6F6`.
- **Siluet Tebing & Pura Uluwatu (`UluwatuCliffPainter`):** Ilustrasi lanskap tebing pantai bergradien teal gelap dan pura meru di bagian bawah kanvas `#2A363B`.

### 2. Checkpoint Selection (`2._checkpoint_selection`)
- Header "Select checkpoint" & "Choose your active checkpoint".
- Kartu pemilihan gate (`Gate 1`, `Gate 2`, `Gate 3`) dengan latar `#212B2F` dan status ketersediaan.
- Gate yang dipilih memiliki border tegas emas `#F5D061` dan custom radio dot aktif (tanpa glow).
- Tombol konfirmasi "Masuk ke Gate" dengan gradien Deep Red `#CF4647` (tanpa glow).

### 3. Dashboard Today (`3._dashboard_today`)
- Header profil petugas ("Raya", "Gate 1") dengan status "Online" hijau. Mengetuk profil membuka **Profile Bottom Sheet**.
- Greeting ramah: "Good afternoon Raya".
- Segmented switch pill: "Today" vs "This Month" dengan pill aktif Deep Red `#CF4647`.
- Kartu metrik utama: **Visitors** (angka besar bold di atas kartu `#212B2F`).
- Grid 2-kolom sekunder: **Valid** (badge centang hijau) & **Rejected** (badge silang deep red `#CF4647`).
- Grafik sebaran pemindaian per jam (*Hourly distribution strip*) dengan highlight bar puncak berwarna Gold `#F5D061`.

### 4. Scanner Viewfinder (`5._scan_check_in`)
- Header informasi gate dan tombol toggle status koneksi online/offline.
- Segmented pill switch: **Check-in** vs **Check** bergradien Deep Red `#CF4647` (tanpa glow).
- Viewfinder kamera dengan 4 reticle corner melengkung berwarna Deep Red (`#CF4647`), crosshair fokus QR di tengah, dan sweeping laser red `#CF4647`.
- Tombol *"Enter code manually"* membuka input teks kode tiket dengan tombol kirim beraksen Gold `#F5D061`.
- Quick demo outcome chips di bawah untuk simulasi langsung (Valid, Already Used, Expired, Invalid).

### 5. Hasil Scan: Valid & Already Used (`8._result_valid` & `9._result_already_used`)
- Overlay feedback layar penuh dengan sheet `#212B2F` yang bersih:
  - **VALID:** Badge lingkaran hijau (`#2ECC71`), ikon centang tebal, teks "VALID", dan tombol "Scan Next".
  - **ALREADY USED:** Badge lingkaran Deep Red (`#CF4647`), ikon silang, teks "ALREADY USED", detail waktu pemindaian sebelumnya, dan tombol "Scan Next".
  - **EXPIRED:** Badge lingkaran Gold (`#F5D061`), teks "EXPIRED".
  - Dilengkapi auto-dismiss countdown timer untuk tiket valid.

### 6. History Screen (`13._history_all`)
- Header "History" & penghitung total pemindaian.
- Segmented filter tabs: **All**, **Valid**, **Rejected** dengan active tab Deep Red `#CF4647`.
- Kartu tiket bergaya dark teal `#212B2F` dengan badge status (centang hijau / silang red `#CF4647`), serial tiket, waktu, jumlah visitor, dan gate. Mengetuk kartu menampilkan detail lengkap.

### 7. Profile Bottom Sheet (`15._profile_bottom_sheet`)
- Drag grabber handle.
- Header profil avatar petugas ("Raya", inisial Gold `#F5D061`).
- Baris interaktif pemilihan Checkpoint (bisa ganti gate langsung).
- Status koneksi (Online/Offline).
- Tombol Logout dengan konfirmasi dialog.

### 8. Floating Navigation Shell (`HomeShell`)
- Floating pill navigation bar di bagian bawah berlatar `#212B2F` dengan efek blur backdrop (`BackdropFilter`) dan border `#3E4E55`.
- 3 tab utama:
  1. **Dashboard** (ikon & label Gold `#F5D061` saat aktif)
  2. **Scan** (tombol lingkaran Deep Red `#CF4647` raised dengan ikon Off-White `#F8F6F6` di tengah)
  3. **History** (ikon & label Gold `#F5D061` saat aktif)

