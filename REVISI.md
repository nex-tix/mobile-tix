# TASK: Comprehensive UI/UX Audit & Improvement — Gate Ticket Scanner App

Lakukan audit dan perbaikan menyeluruh terhadap UI/UX aplikasi berdasarkan codebase aktual dan seluruh screenshot referensi yang tersedia dalam konteks percakapan. Implementasikan perubahan langsung pada project, bukan sekadar memberikan analisis, rencana, atau mockup.

## 1. Aturan Utama

Sebelum mengubah kode:

1. Audit struktur project, tech stack, arsitektur, design system, routing/navigation, state management, API integration, persistence, offline queue, dan test yang tersedia.
2. Identifikasi semua screen, reusable component, dialog, bottom sheet, serta state UI yang berkaitan dengan fitur aplikasi.
3. Periksa implementasi aktual dan bandingkan dengan screenshot referensi. Jangan menyimpulkan bahwa fitur sudah benar hanya karena tampilannya terlihat bagus.
4. Susun prioritas berdasarkan dampak terhadap usability, keakuratan data, keselamatan operasional, dan konsistensi visual.

**Ketentuan wajib:**

* Pertahankan tech stack, arsitektur, business logic, API contract, autentikasi, routing, serta mekanisme persistence yang sudah berfungsi.
* Jangan melakukan rewrite aplikasi atau refactor besar yang tidak diperlukan.
* Jangan menghapus fitur, mengganti endpoint, mengarang data, atau mengubah aturan validasi tiket demi mempermudah implementasi UI.
* Jangan menambahkan dependency jika kemampuan yang dibutuhkan sudah tersedia.
* Gunakan komponen reusable dan design tokens yang konsisten.
* Semua tombol, filter, menu, dan interaksi harus benar-benar berfungsi, bukan hanya dekoratif.
* Jika menemukan bug backend atau kontrak API, dokumentasikan dan tangani sesuai scope tanpa menyamarkannya sebagai masalah UI.

## 2. Design System & Visual Consistency

Audit seluruh aplikasi dan bangun konsistensi visual tanpa menghilangkan identitas desain yang sekarang.

### Warna dan tema

* Pertahankan dark theme sebagai referensi visual utama, tetapi periksa implementasi System, Light, dan Dark jika ketiganya memang didukung.
* Pastikan perubahan tema diterapkan konsisten ke semua halaman, dialog, bottom sheet, status bar, navigation bar, dan komponen input.
* Gunakan semantic color tokens untuk primary, surface, text, border, success, warning, error, dan disabled.
* Pertahankan warna merah untuk aksi utama atau penolakan jika sesuai dengan design system yang ada.
* Gunakan hijau untuk keberhasilan, kuning untuk peringatan, dan merah untuk error atau penolakan.
* Jangan hanya mengandalkan warna: kombinasikan warna dengan ikon dan label yang jelas.
* Periksa kontras teks, placeholder, border, dan ikon pada setiap tema.

### Tipografi dan layout

* Gunakan hierarki tipografi yang jelas untuk page title, section title, body, metadata, dan helper text.
* Konsistenkan spacing, padding, margin, radius, border, elevation, serta ukuran ikon.
* Hindari terlalu banyak border, glow, shadow, atau dekorasi yang tidak membantu pemahaman.
* Pertahankan whitespace yang membantu keterbacaan, tetapi hindari ruang kosong berlebihan yang membuat informasi penting sulit dijangkau.
* Pastikan layout responsif terhadap ukuran layar, system insets, keyboard, safe area, dan perubahan font scale.
* Cegah overflow, clipping, teks bertumpuk, dan komponen tertutup navigation bar.
* Targetkan area sentuh minimal sekitar 48 × 48 dp untuk aksi penting jika sesuai dengan layout platform.

## 3. Dashboard

Audit dan sempurnakan dashboard petugas.

### Header

* Tampilkan avatar/inisial, nama petugas, checkpoint aktif, dan status koneksi secara ringkas.
* Pastikan hierarki informasi jelas dan header tidak memakan terlalu banyak ruang.
* Status online/offline harus mencerminkan kondisi koneksi aktual, bukan nilai statis.

### Statistik

* Pertahankan statistik jumlah pengunjung, valid, dan rejected sesuai sumber data yang tersedia.
* Perjelas label, periode, dan makna setiap angka.
* Pastikan total dan kategori konsisten dengan definisi backend; jangan mengasumsikan semua kategori dapat dijumlahkan tanpa memeriksa business logic.
* Filter Today/This Month harus mengubah data yang ditampilkan, bukan sekadar mengubah tampilan tombol.
* Tangani loading, empty, error, dan refresh dengan jelas.
* Jika sesuai dengan implementasi dan kontrak data, buat kartu statistik dapat membuka History dengan filter relevan.

### Hasil yang diharapkan

Dashboard dapat dipahami sekilas oleh petugas, menampilkan informasi operasional yang relevan, dan tidak memerlukan banyak navigasi untuk memahami kondisi saat ini.

## 4. Scanner / Scan Ticket

Scanner adalah fitur utama aplikasi. Prioritaskan kecepatan, kejelasan hasil, dan pencegahan kesalahan operasional.

### Header dan kontrol

* Tampilkan judul halaman, checkpoint aktif, dan status koneksi.
* Pastikan Check-in dan Check memiliki fungsi serta feedback yang sesuai dengan business logic.
* Bedakan secara jelas operasi pemeriksaan tiket dengan operasi yang benar-benar mencatat check-in.
* Pertahankan input kode manual sebagai alternatif ketika kamera tidak dapat digunakan.
* Tangani permission kamera ditolak, kamera tidak tersedia, inisialisasi gagal, dan kondisi kamera sedang aktif atau berhenti.

### Area pemindaian

* Buat area QR scanner mudah dikenali dengan framing yang proporsional.
* Pastikan ukuran dan posisi area pemindaian tetap nyaman pada layar berbeda.
* Hindari elemen dekoratif yang mengganggu visibilitas kamera atau instruksi scan.
* Berikan petunjuk singkat dan jelas kepada petugas.
* Cegah pemrosesan QR berulang akibat kamera terus membaca kode yang sama.

### Hasil pemindaian

Audit dan pertahankan seluruh status yang benar-benar didukung sistem, termasuk:

* VALID
* ALREADY USED
* EXPIRED
* INVALID TICKET
* CANCELLED

Untuk setiap status:

* Gunakan warna, ikon, judul, dan pesan penjelasan yang konsisten.
* Pastikan status langsung terlihat tanpa perlu membaca detail kecil.
* Tampilkan informasi yang tersedia dan relevan, seperti tipe tiket, jumlah pengunjung, waktu scan, dan checkpoint.
* Untuk ALREADY USED, tampilkan waktu dan checkpoint penggunaan sebelumnya jika data tersedia.
* Untuk EXPIRED, jelaskan bahwa tiket berada di luar periode validitasnya.
* Untuk INVALID dan CANCELLED, tampilkan alasan yang sesuai dengan respons sistem jika tersedia. Jangan mengarang alasan.
* Untuk VALID, bedakan hasil pemeriksaan dari konfirmasi check-in sesuai mode yang digunakan.
* Jangan menganggap status valid secara lokal sama dengan validasi terbaru dari server.

### Bottom sheet hasil scan

* Periksa ukuran, posisi, drag handle, overlay, dan responsivitas bottom sheet.
* Jaga hasil scan tetap menjadi fokus utama.
* Pertahankan ruang kosong jika membantu petugas mengenali hasil dengan cepat; jangan mengubah layout hanya demi mengisi layar.
* Letakkan tombol Scan Next pada posisi yang mudah dijangkau dan konsisten.
* Pastikan Scan Next membersihkan hasil lama, memulihkan scanner, dan memulai pemindaian berikutnya tanpa duplikasi.
* Tangani back gesture, tombol back, dismiss, dan perubahan lifecycle dengan benar.
* Jangan menghilangkan transaksi yang belum tersimpan saat bottom sheet ditutup.

### Feedback

* Gunakan audio/haptic feedback jika sudah didukung dan diizinkan sistem.
* Sediakan feedback visual yang tetap jelas saat suara dimatikan.
* Cegah hasil sebelumnya tertukar dengan hasil scan terbaru.
* Pastikan feedback tidak menghalangi pemindaian berikutnya.

## 5. Offline Mode & Synchronization

Audit alur offline secara menyeluruh, termasuk UI, persistence lokal, antrean, dan proses sinkronisasi.

### Status koneksi

* Bedakan status online, offline, reconnecting jika didukung, dan kegagalan sinkronisasi.
* Status harus berdasarkan kondisi aktual.
* Gunakan banner atau indikator ringkas yang tidak menutupi kontrol utama scanner.
* Hindari menampilkan peringatan berulang yang menyita ruang layar.

### Pending sync

* Tampilkan jumlah transaksi pending secara akurat.
* Berikan penjelasan singkat bahwa transaksi akan disinkronkan saat koneksi tersedia.
* Izinkan banner detail ditutup tanpa menyembunyikan indikator status sinkronisasi penting.
* Jika tersedia, tampilkan status syncing, synced, failed, dan retrying secara konsisten.
* Jangan mengklaim sinkronisasi berhasil sebelum server mengonfirmasi keberhasilan.

### Keandalan data

* Pastikan transaksi yang diklaim tersimpan offline benar-benar sudah dipersistenkan secara lokal.
* Tangani kegagalan penyimpanan lokal secara eksplisit.
* Pertahankan antrean ketika aplikasi ditutup, dibuka ulang, atau perangkat kehilangan koneksi.
* Audit retry, idempotency, duplicate prevention, urutan transaksi, dan konflik data.
* Hindari pengiriman transaksi yang sama berulang kali hingga menghasilkan check-in ganda.
* Pisahkan status bisnis tiket dari status sinkronisasi. Contoh: tiket dapat berstatus valid secara lokal, tetapi transaksi check-in masih menunggu konfirmasi server.
* Jangan mengubah kebijakan validasi offline atau mengizinkan check-in yang tidak aman tanpa dasar pada business logic.
* Jika validitas offline tidak dapat dipastikan, tampilkan keterbatasannya dengan jelas.

### Contoh komunikasi UI

* Offline: “Koneksi terputus. Transaksi tersimpan di perangkat dan menunggu sinkronisasi.” Gunakan hanya setelah penyimpanan lokal berhasil.
* Pending: “2 transaksi menunggu sinkronisasi.”
* Syncing: “Menyinkronkan transaksi…”
* Synced: “Semua transaksi berhasil disinkronkan.”
* Failed: “Sinkronisasi gagal. Transaksi tetap tersimpan jika persistence lokal masih terkonfirmasi.”

Sesuaikan teks dengan kemampuan nyata aplikasi. Jangan menjanjikan retry otomatis jika mekanismenya belum tersedia.

## 6. History

History harus memudahkan petugas menemukan transaksi tertentu dengan cepat.

### Header dan pencarian

* Rapikan judul History dan jumlah transaksi.
* Pertahankan pencarian berdasarkan ticket ID atau nama pengunjung jika kedua field tersedia.
* Pastikan pencarian berjalan terhadap data yang relevan, menangani input kosong, whitespace, clear action, loading, dan hasil tidak ditemukan.
* Gunakan debounce jika pencarian memicu request berulang dan pola project mendukungnya.

### Filter dan sorting

* Pertahankan filter status, sorting waktu, dan filter checkpoint/gate sesuai fitur yang tersedia.
* Pastikan setiap filter benar-benar memengaruhi dataset, bukan hanya selected state.
* Bedakan filter status dari sorting waktu dan filter gate.
* Gunakan label yang eksplisit, seperti “Semua status”, “Terbaru”, dan “Semua gate”.
* Perbaiki urutan transaksi berdasarkan timestamp yang benar, termasuk tanggal, bukan hanya jam.
* Tangani timestamp kosong atau invalid dengan aman.
* Pertahankan filter saat pengguna membuka dan menutup detail transaksi jika sesuai dengan perilaku navigasi yang ada.

### Daftar transaksi

* Pertahankan ticket ID sebagai informasi utama.
* Tampilkan status melalui ikon dan warna.
* Tampilkan waktu scan, jumlah pengunjung, dan checkpoint dengan hierarki yang jelas.
* Samakan format label dan satuan jumlah pengunjung.
* Pastikan setiap item memiliki area sentuh yang memadai.
* Periksa loading skeleton, empty state, error state, refresh, dan pagination jika didukung.

### Ticket Detail

* Tampilkan ticket ID, status, waktu scan, checkpoint, jumlah pengunjung, dan petugas.
* Gunakan format tanggal/waktu yang konsisten dan mudah dibaca.
* Bedakan status tiket dengan status sinkronisasi.
* Untuk tiket yang sudah digunakan, tampilkan riwayat penggunaan sebelumnya jika tersedia.
* Pastikan detail berasal dari transaksi yang benar dan tidak menggunakan data item lain akibat state yang tertinggal.
* Atur alignment label dan nilai agar mudah dipindai secara visual.
* Pastikan bottom sheet tetap nyaman pada layar kecil dan saat font scale diperbesar.

## 7. Officer Profile & Settings

* Rapikan profil petugas, avatar/inisial, nama, dan role.
* Tampilkan Theme, Language, Checkpoint, dan Connection dengan label serta nilai yang konsisten.
* Pastikan perubahan Theme dan Language benar-benar diterapkan ke seluruh aplikasi jika fitur tersebut tersedia.
* Pastikan checkpoint yang ditampilkan merupakan checkpoint aktif yang sebenarnya.
* Tampilkan status koneksi aktual.
* Tambahkan konfirmasi sebelum logout jika sesuai pola aplikasi.
* Jangan menghapus antrean transaksi pending atau data penting secara tidak sengaja ketika logout.
* Tangani token/session cleanup sesuai arsitektur autentikasi yang sudah ada.
* Pastikan navigasi kembali bekerja dengan benar.

## 8. Bottom Navigation & Global Interaction

* Pertahankan navigasi utama Dashboard, Scan, dan History jika sesuai dengan routing saat ini.
* Scanner tetap mudah diakses sebagai aksi utama.
* Pastikan active state, ikon, label, warna, dan touch target konsisten.
* Periksa safe area dan posisi navigation bar pada berbagai ukuran layar.
* Hindari overlap dengan keyboard, bottom sheet, snackbar, dan hasil scan.
* Pastikan back navigation tidak menyebabkan kehilangan data atau membuka halaman yang salah.
* Jangan mengubah pola navigasi yang sudah dipahami pengguna tanpa alasan usability yang kuat.

## 9. Localization & Copywriting

Audit seluruh teks UI, bukan hanya halaman yang terlihat pada screenshot.

* Pastikan bahasa Indonesia dan Inggris konsisten berdasarkan pengaturan bahasa.
* Jangan mencampur kedua bahasa dalam satu halaman kecuali istilah teknis yang memang perlu dipertahankan.
* Konsistenkan istilah: petugas/officer, checkpoint/gate, pengunjung/visitor, scan/pemindaian, check-in, pending sync.
* Gunakan kalimat singkat, spesifik, dan berorientasi pada tindakan.
* Hindari pesan error yang hanya menampilkan exception teknis.
* Jangan menerjemahkan enum, API field, atau identifier internal dengan cara yang mengubah nilai data.
* Periksa pluralisasi, format tanggal, waktu, dan jumlah pengunjung.

## 10. Accessibility & Usability

* Periksa kontras warna pada dark dan light theme.
* Jangan mengandalkan warna saja untuk membedakan status.
* Pastikan ukuran teks, ikon, dan area sentuh memadai.
* Pastikan elemen penting tetap terlihat ketika font scale diperbesar.
* Pastikan keyboard, fokus input, dan dismiss behavior bekerja dengan baik.
* Minimalkan jumlah interaksi untuk tugas berulang.
* Hindari dialog konfirmasi yang tidak diperlukan untuk setiap scan.
* Pastikan error menjelaskan masalah dan langkah berikutnya secara singkat.

## 11. Testing & Regression Prevention

Sebelum menyelesaikan tugas:

1. Tambahkan atau perbarui unit test untuk perubahan pada state management, filter/sorting History, validasi status, dan sinkronisasi offline jika relevan.
2. Tambahkan widget/UI test untuk interaksi penting jika infrastruktur test sudah tersedia.
3. Verifikasi alur Check-in dan Check tidak saling tertukar.
4. Verifikasi setiap hasil scan dan tombol Scan Next.
5. Verifikasi pencarian, filter, sorting, dan detail History.
6. Verifikasi offline, antrean pending, reconnect, retry, dan kegagalan persistence sesuai kemampuan implementasi.
7. Jalankan formatter, analyzer/linter, test, dan build yang relevan dengan project.
8. Perbaiki error yang muncul akibat perubahanmu.
9. Jika emulator atau screenshot test tersedia, periksa overflow, alignment, kontras, safe area, dan konsistensi tema pada halaman utama.
10. Jangan menyatakan test atau build berhasil jika perintah tersebut belum benar-benar dijalankan.

Jangan mengubah test agar sekadar lulus tanpa memperbaiki implementasi atau menyesuaikan ekspektasi yang memang sudah tidak valid.

## 12. Prioritas Implementasi

Kerjakan dengan urutan berikut:

**P0 — Correctness & reliability**

* Validasi hasil scan.
* Pencegahan scan/transaksi duplikat.
* Persistence offline.
* Sinkronisasi dan penanganan error.
* Pemisahan status tiket dan status sync.

**P1 — Core usability**

* Scanner dan hasil scan.
* History, filter, sorting, dan detail.
* Konsistensi bahasa.
* Navigasi dan bottom sheet.

**P2 — Visual refinement**

* Dashboard dan profil.
* Design tokens, spacing, typography, warna, ikon.
* Responsivitas dan accessibility.
* Loading, empty, dan error state.

Jangan berhenti setelah satu fase. Lanjutkan sampai seluruh scope selesai atau ada blocker nyata.

## 13. Definition of Done

Pekerjaan dianggap selesai jika:

* Semua halaman dan state terkait sudah diaudit dan diperbaiki.
* Tidak ada interaksi utama yang hanya bersifat dekoratif.
* Design system dan localization konsisten.
* Alur scanner, History, dan offline tetap sesuai business logic.
* Tidak ada regresi yang diketahui akibat perubahan.
* Formatter, analyzer, test, dan build yang relevan telah dijalankan, dengan hasil dilaporkan secara jujur.
* Tidak ada overflow atau komponen penting yang tertutup pada layout yang diuji.
* Dokumentasi diperbarui jika perilaku atau konfigurasi yang relevan berubah.

## 14. Laporan Akhir

Setelah implementasi, laporkan:

1. Ringkasan masalah utama yang ditemukan.
2. Perbaikan yang diterapkan per halaman dan fitur.
3. File utama yang diubah beserta tujuan perubahannya.
4. Test, analyzer, formatter, dan build yang dijalankan beserta hasil aktual.
5. Bug yang belum terselesaikan, blocker, serta risiko yang masih tersisa.
6. Perubahan yang membutuhkan verifikasi manual di perangkat nyata.

**Mulai dengan mengaudit codebase aktual, kemudian langsung implementasikan perbaikan secara menyeluruh. Jangan hanya membuat rencana dan jangan meminta konfirmasi untuk setiap perubahan kecil yang sudah tercakup dalam scope ini.**
