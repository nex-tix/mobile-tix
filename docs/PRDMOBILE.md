# Pembagian Tugas PRD

## Sistem Ticketing POS Loket Web & Mobile Validator Gate

Dokumen ini memisahkan tanggung jawab Web dan Mobile berdasarkan PRD v2.5. Fokus utama dokumen ini adalah bagian Mobile Validator karena bagian tersebut menjadi tanggung jawab developer Mobile.

## 1. Gambaran Sistem

Platform:

- Web internal: Role Admin
- Mobile Android: Role Gate
- Backend/API: CodeIgniter 4 REST API
- Mobile: Flutter / Dart
- Database: MySQL 8.0.16+
- Zona waktu: WITA / Asia/Makassar

Arsitektur:

```text
Web POS
   ↓
CodeIgniter 4
   ↓
MySQL

Flutter Android
   ↓
REST API
   ↓
CodeIgniter 4
   ↓
MySQL
```

Mobile tidak mengakses database secara langsung.

---

# BAGIAN MOBILE

## 2. Tanggung Jawab Mobile

Mobile Validator digunakan petugas Gate untuk:

1. Login petugas.
2. Memilih checkpoint/gate.
3. Scan QR tiket.
4. Melakukan validasi tiket.
5. Melakukan check-in tiket.
6. Mengecek tiket tanpa menggunakannya.
7. Menampilkan hasil scan.
8. Menampilkan dashboard jumlah pengunjung.
9. Menampilkan riwayat scan.
10. Memasukkan kode tiket secara manual.
11. Memberikan feedback suara dan getar.
12. Menangani kondisi koneksi terputus.

## 3. Platform

- Flutter
- Dart
- Android 8.0+ / API 26
- Kamera untuk QR scanner
- Komunikasi melalui REST API
- HTTPS

## 4. Login dan Sesi

### Login Screen

Input:

- Username
- Password

API:

```text
POST /api/login
```

Setelah login berhasil:

- Simpan token.
- Ambil data akun.
- Ambil daftar checkpoint.
- Petugas memilih checkpoint aktif.

### Token

- Token bersifat random/opaque.
- Token berlaku 12 jam.
- Logout mencabut token.
- Setiap request menggunakan token.
- API memperbarui `last_used_at`.

API terkait:

```text
POST /api/login
POST /api/logout
GET  /api/me
GET  /api/checkpoints
```

## 5. Pemilihan Checkpoint

Setelah login, petugas memilih checkpoint aktif.

Contoh:

```text
Pilih Gate

[ Gate 1 ]
[ Gate 2 ]
```

Data checkpoint diperoleh dari:

```text
GET /api/checkpoints
```

Checkpoint yang dipilih digunakan untuk sesi scanning.

---

# 6. Scanner QR

Scanner merupakan fitur utama Mobile Validator.

PRD menyebut contoh package:

```text
mobile_scanner
```

Fitur yang dibutuhkan:

- QR scanner native.
- Continuous scanning.
- Controller tidak dimuat ulang setiap scan.
- Debounce sekitar 1 detik.
- Beep ketika scan berhasil.
- Dua bunyi ketika scan ditolak.
- Getar.
- Otomatis kembali ke scanner setelah hasil ditampilkan.
- Input kode tiket manual sebagai alternatif.

Target respons API pada jaringan normal:

```text
< 1 detik
```

## 7. Dua Mode Scanner

Scanner memiliki dua mode.

### Mode Check-in

Mode default.

Alur:

```text
Scan QR
   ↓
POST /api/ticket/validate-and-checkin
   ↓
Server melakukan validasi
   ↓
Jika valid
   ↓
Ticket active → used
   ↓
Tampilkan hasil
```

Mode ini benar-benar menggunakan tiket.

### Mode Cek

Alur:

```text
Scan QR
   ↓
POST /api/ticket/check
   ↓
Server membaca data tiket
   ↓
Tampilkan status
```

Mode Cek:

- Tidak mengubah status tiket.
- Tidak dicatat ke riwayat.
- Tidak memengaruhi metrik dashboard.

Tersedia tombol "Check-in sekarang" jika tiket valid.

---

# 8. Hasil Scan

Mobile harus menangani lima hasil utama.

| Result         | Tampilan | Keterangan                           |
| -------------- | -------- | ------------------------------------ |
| `VALID`        | Hijau    | Tiket active dan berlaku hari ini    |
| `ALREADY_USED` | Merah    | Tiket sudah digunakan                |
| `EXPIRED`      | Kuning   | Tiket sudah melewati tanggal berlaku |
| `NOT_FOUND`    | Abu-abu  | Kode tiket tidak ditemukan           |
| `CANCELLED`    | Merah    | Tiket dibatalkan melalui void        |

### VALID

Tampilkan:

- Jenis tiket.
- Jumlah pengunjung.
- Nama pembawa.
- Rincian rombongan jika tiket group.

### ALREADY_USED

Tampilkan:

- Waktu penggunaan.
- Petugas.
- Gate/checkpoint.

### EXPIRED

Tampilkan:

- Tanggal berlaku tiket.

### NOT_FOUND

Tampilkan:

- Kode tiket tidak ditemukan.

### CANCELLED

Tampilkan:

- Tiket telah dibatalkan.

---

# 9. Dashboard

Mobile mempunyai dashboard jumlah pengunjung.

Periode:

```text
Hari Ini
Bulan Ini
```

Metrik:

- Total pengunjung masuk.
- Total tiket valid.
- Total tiket ditolak.

Data hanya dihitung dari scan Mode Check-in.

API:

```text
GET /api/dashboard/summary
```

Parameter:

```text
period=today
period=month
```

---

# 10. Riwayat Validasi

Mobile menampilkan riwayat scan milik petugas yang sedang login.

Urutan:

- Terbaru di atas.

Data:

- Kode tiket.
- Waktu scan.
- Hasil.
- Checkpoint.
- Jumlah orang.

Scan yang ditolak tetap dicatat.

API:

```text
GET /api/ticket/history
```

---

# 11. Input Kode Manual

Jika QR rusak atau tidak dapat dibaca, petugas dapat memasukkan kode secara manual.

Contoh:

```text
Masukkan kode tiket

[TKT-XXXXXXXXXXXX]

[Periksa]
```

Input manual menggunakan endpoint validasi yang sama dengan scanner sesuai mode yang sedang aktif.

---

# 12. Koneksi Terputus

Mobile membutuhkan koneksi internet.

Jika koneksi terputus:

- Tampilkan pesan koneksi terputus.
- Scan tidak diproses.
- Tidak ada antrean offline.

Jika koneksi terputus tepat saat scan:

```text
Scan ulang
   ↓
Jika ALREADY_USED dengan waktu baru
   ↓
Kemungkinan scan sebelumnya berhasil
```

Mode Cek dapat digunakan untuk memastikan status tiket.

---

# 13. API yang Perlu Diintegrasikan

| Method | Endpoint                           | Fungsi                    |
| ------ | ---------------------------------- | ------------------------- |
| POST   | `/api/login`                       | Login petugas Gate        |
| POST   | `/api/logout`                      | Logout dan mencabut token |
| GET    | `/api/me`                          | Informasi akun            |
| GET    | `/api/checkpoints`                 | Daftar checkpoint aktif   |
| POST   | `/api/ticket/check`                | Mode Cek                  |
| POST   | `/api/ticket/validate-and-checkin` | Validasi dan check-in     |
| GET    | `/api/dashboard/summary`           | Dashboard                 |
| GET    | `/api/ticket/history`              | Riwayat scan              |

Semua API menggunakan prefix:

```text
/api
```

Format:

- HTTPS
- JSON UTF-8
- Waktu menggunakan ISO 8601 dengan offset WITA.

---

# 14. Struktur Screen Mobile

Struktur berdasarkan kebutuhan PRD:

```text
LoginScreen
    ↓
CheckpointScreen
    ↓
HomeScreen
    ├── Scanner
    ├── Dashboard
    └── History
```

Scanner:

```text
ScannerScreen
    ├── QR Camera
    ├── Mode Check-in / Cek
    ├── Manual Ticket Code
    └── ScanResult
```

Dashboard:

```text
DashboardScreen
    ├── Hari Ini
    └── Bulan Ini
```

History:

```text
HistoryScreen
    └── List Scan
```

---

# 15. Package Flutter yang Kemungkinan Dibutuhkan

Package utama:

```text
mobile_scanner
dio
provider
flutter_secure_storage
```

Fungsinya:

| Package                  | Fungsi                        |
| ------------------------ | ----------------------------- |
| `mobile_scanner`         | Scan QR                       |
| `dio`                    | HTTP client untuk REST API    |
| `provider`               | State management              |
| `flutter_secure_storage` | Penyimpanan token secara aman |

Package suara/getar dapat ditambahkan sesuai implementasi.

---

# BAGIAN WEB

## 16. Tanggung Jawab Web

Bagian Web/Admin menangani:

1. Login Admin.
2. POS loket.
3. Data pengunjung.
4. Penjualan tiket.
5. Perhitungan harga.
6. Diskon.
7. Pembayaran Cash.
8. Pembayaran Debit.
9. Generate kode tiket.
10. Generate QR.
11. Cetak thermal.
12. Riwayat transaksi.
13. Cetak ulang tiket.
14. Void transaksi.
15. Master User.
16. Master Jenis Tiket.
17. Master Checkpoint.
18. Pengaturan.
19. Dashboard Admin.
20. Laporan.
21. Export PDF.
22. Export Excel.

---

# 17. Yang Tidak Perlu Dikerjakan Developer Mobile

Developer Mobile tidak perlu membuat:

- MySQL.
- Database schema.
- POS.
- Form pembelian tiket.
- Perhitungan harga.
- Sistem diskon.
- Pembayaran Cash.
- Pembayaran Debit.
- Generate QR.
- Printer thermal.
- Cetak ulang.
- Void transaksi.
- Laporan Admin.
- Export PDF.
- Export Excel.
- Master data Admin.

Backend bertanggung jawab terhadap validasi sebenarnya.

Flutter bertugas:

- Mengirim request.
- Menerima response.
- Mengelola state.
- Menampilkan data.
- Menangani interaksi pengguna.

---

# 18. Task List Developer Mobile

## Setup

- [ ] Setup project Flutter.
- [ ] Setup struktur folder.
- [ ] Install `dio`.
- [ ] Install `provider`.
- [ ] Install `mobile_scanner`.
- [ ] Install `flutter_secure_storage`.
- [ ] Setup API base URL.
- [ ] Setup API client.
- [ ] Setup authentication interceptor.

## Authentication

- [ ] Login screen.
- [ ] Login API.
- [ ] Token storage.
- [ ] Logout.
- [ ] Get current user.
- [ ] Check token/session.

## Checkpoint

- [ ] Get checkpoint API.
- [ ] Checkpoint selection.
- [ ] Simpan checkpoint aktif.

## Scanner

- [ ] QR scanner.
- [ ] Continuous scanning.
- [ ] Debounce.
- [ ] Mode Check-in.
- [ ] Mode Cek.
- [ ] Manual ticket code.
- [ ] Feedback suara.
- [ ] Feedback getar.
- [ ] Auto return ke scanner.

## Result

- [ ] VALID.
- [ ] ALREADY_USED.
- [ ] EXPIRED.
- [ ] NOT_FOUND.
- [ ] CANCELLED.

## Dashboard

- [ ] Dashboard Hari Ini.
- [ ] Dashboard Bulan Ini.
- [ ] Total pengunjung.
- [ ] Total tiket valid.
- [ ] Total ditolak.

## History

- [ ] History API.
- [ ] List scan.
- [ ] Status scan.
- [ ] Waktu scan.
- [ ] Checkpoint.
- [ ] Jumlah pengunjung.

## Error Handling

- [ ] Internet terputus.
- [ ] API error.
- [ ] Token expired.
- [ ] Token revoked.
- [ ] QR tidak valid.
- [ ] Server error.
- [ ] Timeout.

## Testing

- [ ] Login berhasil.
- [ ] Login gagal.
- [ ] Scan tiket VALID.
- [ ] Scan tiket ALREADY_USED.
- [ ] Scan tiket EXPIRED.
- [ ] Scan tiket NOT_FOUND.
- [ ] Scan tiket CANCELLED.
- [ ] Mode Cek.
- [ ] Check-in.
- [ ] Scan bersamaan.
- [ ] Internet terputus.
- [ ] Token expired.
- [ ] Logout.
- [ ] Dashboard.
- [ ] History.
- [ ] Manual input.

---

# 19. Pembagian Kerja Singkat

## Mobile

```text
Flutter
  ↓
Login
  ↓
Checkpoint
  ↓
Scanner
  ↓
REST API
  ↓
Result
  ↓
Dashboard / History
```

## Web

```text
Admin
  ↓
POS
  ↓
Transaksi
  ↓
Pembayaran
  ↓
Ticket + QR
  ↓
Printer
  ↓
Database
```

## Backend

```text
REST API
  ↓
Authentication
  ↓
Ticket Validation
  ↓
Check-in Atomik
  ↓
Dashboard
  ↓
History
  ↓
MySQL
```

# 20. Fokus Utama Developer Mobile

Urutan pengerjaan yang paling masuk akal:

1. Belajar Dio.
2. Belajar Provider.
3. Buat API client.
4. Buat login.
5. Simpan token.
6. Buat checkpoint selection.
7. Buat scanner.
8. Hubungkan scanner ke API.
9. Buat hasil scan.
10. Buat Mode Cek.
11. Buat dashboard.
12. Buat history.
13. Tambahkan manual input.
14. Tambahkan suara/getar.
15. Handle error dan koneksi.
16. Testing dengan backend.

Target akhirnya:

```text
Login
  ↓
Pilih Gate
  ↓
Scan QR
  ↓
API
  ↓
Validasi
  ↓
VALID / ALREADY_USED / EXPIRED / NOT_FOUND / CANCELLED
  ↓
Kembali Scan
```

Dokumen ini mengikuti PRD v2.5, khususnya bagian Modul Mobile Validator, REST API, keamanan, teknologi, dan Sprint 5 Mobile Validator.
