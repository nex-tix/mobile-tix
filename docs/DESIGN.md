Kamu adalah Flutter UI/UX Engineer.

Tugas kamu HANYA mendesain dan mengimplementasikan UI/UX aplikasi Mobile Ticket Validator ke project Flutter yang SUDAH ADA.

PENTING:

Ini adalah tahap UI/UX DESIGN ONLY.

JANGAN mengerjakan business logic, API integration, authentication logic, database, repository, service, atau backend.

Semua data yang diperlukan untuk menampilkan UI gunakan DUMMY / MOCK DATA.

==================================================
GOAL
====

Saya ingin melihat bagaimana aplikasi Mobile Ticket Validator akan terlihat dan terasa ketika digunakan.

Kamu harus LANGSUNG BUILD UI-NYA ke project Flutter yang sudah ada.

Jangan hanya memberikan desain, screenshot concept, atau potongan kode.

Edit file Flutter yang diperlukan dan buat seluruh screen UI sampai bisa dijalankan.

Namun, semua functionality cukup berupa simulasi menggunakan dummy data.

==================================================
PROJECT RULES
=============

Project Flutter sudah tersedia.

Pertahankan struktur folder yang sudah dibuat.

Struktur utamanya:

lib/
├── core/
│   ├── api/
│   ├── config/
│   ├── storage/
│   ├── connectivity/
│   ├── error/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── checkpoint/
│   ├── scanner/
│   ├── dashboard/
│   └── history/
│
├── shared/
└── routes/

Gunakan struktur tersebut.

JANGAN membuat architecture baru seperti:

lib/screens/
lib/pages/
lib/controllers/
lib/bloc/

Jangan mengganti architecture project.

==================================================
STRICT UI-ONLY RULE
===================

Kamu BOLEH:

* Membuat screen UI
* Membuat widget
* Membuat reusable components
* Membuat theme
* Membuat color system
* Membuat typography
* Membuat spacing system
* Membuat animations sederhana
* Membuat bottom sheet
* Membuat navigation UI untuk demo
* Membuat dummy/mock data
* Membuat dummy state
* Membuat simulated loading
* Membuat simulated scan result
* Membuat simulated error state
* Membuat simulated offline state

Kamu TIDAK BOLEH:

* Mengintegrasikan API
* Memanggil endpoint backend
* Mengubah endpoint API
* Mengubah Dio configuration
* Mengubah repository
* Mengubah service
* Mengubah authentication system
* Mengubah token handling
* Mengubah database
* Mengubah model backend
* Mengubah Provider logic yang sudah ada
* Membuat real authentication
* Membuat real QR validation
* Membuat real scanner validation
* Membuat offline queue
* Mengubah business logic
* Mengubah backend
* Mengubah database schema

Jika functionality diperlukan hanya untuk memperlihatkan UI, gunakan dummy/mock implementation.

==================================================
LOGO
====

Saya sudah menyediakan logo:

logo.png

File tersebut berada di root project.

WAJIB gunakan logo tersebut.

Jangan membuat logo baru.

Jangan mengganti logo dengan icon.

Jika perlu, tambahkan `logo.png` ke assets di `pubspec.yaml`.

Gunakan logo pada:

* Login
* Splash/loading jika diperlukan
* Branding yang relevan

Pastikan aspect ratio logo tidak berubah.

==================================================
DESIGN DIRECTION
================

Desain harus:

Clean
Modern
Professional
Friendly
Operational
Slightly premium
Minimal
Custom

Aplikasi ini adalah aplikasi operasional untuk petugas gate.

Jangan membuatnya seperti:

* AI dashboard generic
* Cyberpunk
* Gaming
* Neon
* Banking app
* Social media
* Glassmorphism
* Excessive gradient
* Excessive glow
* Excessive shadows
* Template Flutter default
* UI penuh card
* Giant illustration

Desain harus terasa seperti aplikasi produk nyata.

Gunakan Material 3 sebagai foundation, tetapi customize agar tidak terlihat seperti default Material 3.

==================================================
COLOR PALETTE
=============

Primary:

#CF4647

Secondary:

#F5D061

Background:

#F8F6F6

Dark Text:

#2A363B

Status:

VALID:
Green

ALREADY_USED:
Red

EXPIRED:
Gold / Yellow

NOT_FOUND:
Gray

CANCELLED:
Red

Gunakan status color sebagai accent, bukan memenuhi seluruh screen.

==================================================
TYPOGRAPHY
==========

Gunakan clean sans-serif.

Screen title:
24-28 px bold

Section:
18-20 px semibold

Body:
14-16 px

Supporting:
12-14 px

Dashboard number:
28-36 px

Result status:
20-24 px

==================================================
SPACING
=======

Gunakan:

4
8
12
16
20
24
32
40

Main horizontal padding:

20-24 px

Touch target minimum:

48 px

Button height:

50-54 px

Radius:

14-18 px

Bottom sheet:

24 px top radius

==================================================
SCREEN 1: LOGIN
===============

Build login UI.

Tampilkan:

Logo

Gate Validator

Mobile Ticket Validator

Username field

Password field

MASUK button

Gunakan dummy credentials.

Contoh:

Username:
admin.gate

Password:
••••••••

Ketika button ditekan, cukup simulasi login dan masuk ke checkpoint selection.

Tidak ada API.

Tidak ada authentication asli.

==================================================
SCREEN 2: CHECKPOINT SELECTION
==============================

Title:

Pilih Checkpoint

Subtitle:

Pilih gate tempat Anda bertugas.

Gunakan dummy checkpoint:

Gate 1
Pintu Masuk Utama

Gate 2
Pintu Masuk Selatan

Gate 3
Pintu Masuk Barat

User dapat memilih checkpoint secara visual.

Setelah memilih, masuk ke main application UI.

==================================================
MAIN APP
========

Main navigation:

Scanner
Dashboard
History
Profile

Scanner adalah default screen.

Navigation harus clean dan compact.

==================================================
SCREEN 3: SCANNER
=================

Scanner harus menjadi visual utama aplikasi.

Karena tahap ini UI ONLY:

JANGAN implementasikan QR scanner asli.

Gunakan dummy camera/scanner area.

Camera area dapat berupa:

* simulated camera preview
* dark camera placeholder
* dummy QR visual

Buat custom QR scanning frame.

Gunakan:

* rounded scanning frame
* corner indicators
* subtle scanning animation

Jangan gunakan neon.

Tambahkan:

Gate 1
Online

Mode:

CHECK-IN
CEK

Gunakan segmented control.

Tambahkan manual ticket input.

Contoh dummy ticket:

TKT-2026-001245

Button:

SCAN / CEK

Semua interaksi cukup simulated.

==================================================
DUMMY SCAN FLOW
===============

Buat simulasi scan.

Misalnya user menekan area scanner atau tombol demo.

Tampilkan Scan Result Bottom Sheet.

Gunakan dummy result.

Contoh:

VALID

Ticket:
TKT-2026-001245

Visitor:
John Doe

Category:
Individual

Checkpoint:
Gate 1

Time:
14:32

Bottom sheet otomatis tertutup setelah beberapa detik.

Setelah itu scanner kembali ke keadaan awal.

Tidak ada API.

==================================================
SCAN RESULT STATES
==================

Buat UI yang mampu menampilkan beberapa dummy status:

VALID

ALREADY_USED

EXPIRED

NOT_FOUND

CANCELLED

Gunakan status yang berbeda untuk menunjukkan desain.

Pastikan masing-masing status memiliki visual hierarchy yang jelas.

==================================================
CAMERA PERMISSION STATE
=======================

Buat juga dummy UI untuk permission state.

Tampilkan:

Akses kamera diperlukan

Kamera digunakan untuk membaca QR tiket.

Button:

BUKA PENGATURAN

Button hanya simulasi.

Tidak perlu membuka Android Settings.

==================================================
OFFLINE STATE
=============

Buat dummy offline banner:

"Anda sedang offline"

Scanner tetap terlihat tetapi scan action dapat dibuat disabled.

Jangan implementasikan connectivity logic.

==================================================
SCREEN 4: DASHBOARD
===================

Title:

Dashboard

Active checkpoint:

Gate 1

Period:

HARI INI
BULAN INI

Dummy metrics:

Masuk
128

Valid
121

Ditolak
7

Gunakan desain yang clean.

Jangan membuat chart palsu yang kompleks.

Dashboard jangan terlalu banyak card.

==================================================
SCREEN 5: HISTORY
=================

Buat history menggunakan dummy data.

Contoh:

TKT-2026-001245
14:32
Gate 1
1 tiket
VALID

TKT-2026-001244
14:27
Gate 1
2 tiket
ALREADY_USED

TKT-2026-001243
14:20
Gate 1
1 tiket
EXPIRED

TKT-2026-001242
14:12
Gate 1
3 tiket
VALID

Urutan newest first.

Gunakan activity-list style.

Jangan membuat giant cards.

Tambahkan dummy empty state.

==================================================
SCREEN 6: PROFILE
=================

Operational profile.

Dummy data:

Nama:
Admin Gate

Role:
Gate Staff

Checkpoint:
Gate 1

Connection:
Online

Actions:

Ganti Checkpoint

Logout

Semua hanya simulasi.

Logout cukup kembali ke login screen.

==================================================
REUSABLE COMPONENTS
===================

Buat reusable UI components jika diperlukan:

AppButton
AppTextField
StatusBadge
MetricCard
CheckpointCard
ScanResultSheet
SectionHeader
OfflineBanner
EmptyState
LoadingState

Pastikan komponen memiliki visual consistency.

==================================================
MICRO INTERACTIONS
==================

Tambahkan interaksi sederhana untuk membuat prototype terasa hidup:

* button press
* selected checkpoint
* tab switching
* scanner animation
* bottom sheet animation
* loading state
* status transition
* toggle mode

Tetap subtle.

Jangan menggunakan animasi berlebihan.

==================================================
RESPONSIVE
==========

UI harus nyaman pada:

Small Android phone
Medium Android phone
Large Android phone

Pastikan tidak ada:

* overflow
* clipped text
* keyboard overlap
* bottom navigation overflow
* bottom sheet overflow

==================================================
EMPTY / LOADING / ERROR STATES
==============================

Buat UI state untuk:

Loading

Empty history

Scanner permission

Offline

Validation success

Validation failed

Ticket not found

Expired ticket

Already used ticket

Semua menggunakan dummy state.

==================================================
IMPLEMENTATION
==============

Sekarang langsung kerjakan.

WORKFLOW:

1. Inspect project yang sudah ada.
2. Inspect struktur `lib/`.
3. Inspect existing UI.
4. Inspect `pubspec.yaml`.
5. Pastikan `logo.png` dapat digunakan.
6. Buat/update design system.
7. Implement Login UI.
8. Implement Checkpoint UI.
9. Implement Scanner UI.
10. Implement Scan Result UI.
11. Implement Dashboard UI.
12. Implement History UI.
13. Implement Profile UI.
14. Implement semua dummy states.
15. Implement dummy navigation.
16. Implement dummy interactions.
17. Jalankan formatter.
18. Jalankan analyzer.
19. Perbaiki error UI/compile yang muncul akibat implementasi desain.

==================================================
FINAL RESTRICTION
=================

INGAT:

INI HANYA TAHAP DESIGN / UI/UX.

Jangan mengerjakan backend.

Jangan mengerjakan API.

Jangan mengerjakan database.

Jangan mengerjakan authentication.

Jangan mengerjakan real QR scanner.

Jangan mengerjakan business logic.

Jangan mengubah architecture.

Jangan mengubah logic existing.

Gunakan DUMMY DATA untuk seluruh tampilan.

Tujuan akhir:

Saya ingin mendapatkan Flutter app prototype yang bisa saya jalankan di emulator/Android dan melihat seluruh UI/UX Mobile Ticket Validator secara langsung.

BUILD THE UI DIRECTLY INTO THE EXISTING FLUTTER PROJECT.

DO NOT IMPLEMENT REAL BUSINESS LOGIC.
