# NoteCraft 📝✨

Aplikasi Catatan & To-Do List Mobile modern berbasis Flutter dengan Material 3, penyimpanan lokal *offline-first*, sistem pengingat notifikasi harian, dan penjadwalan multi-dimensi (Hari, Tanggal, Minggu, Bulan, dan Jam) dalam satu catatan.

---

## 🌟 Fitur Utama

- 🗓️ **Penjadwalan Multi-Dimensi per Item**:
  - Atur jadwal aktivitas berdasarkan Hari, Tanggal, Jam, Minggu Depan, atau Bulan Depan di setiap baris tugas dalam satu container catatan.
  - Pilihan cepat (Hari Ini, Besok, Minggu Depan, Bulan Depan), kalender DatePicker interaktif, atau ketik jadwal kustom.
- 🔔 **Pengingat & Alarm Notifikasi Harian**:
  - Pengingat harian berulang otomatis (*Setiap Pagi 08:00*, *Setiap Malam 19:00*, atau *Jam Kustom*).
  - Pengingat rutin harian global aplikasi untuk cek agenda & tugas prioritas.
  - Tombol uji coba notifikasi instan langsung ke bilah status HP.
- 🔀 **Pengurutan Fleksibel (7 Opsi)**:
  - Urutkan berdasarkan Terakhir Diedit (Terbaru/Terlama), Tanggal Dibuat (Terbaru/Terlama), Prioritas Tertinggi, serta Judul (A-Z / Z-A).
- 🔴🟡🟢 **Tingkat Prioritas Catatan**:
  - Tandai catatan dengan 4 level prioritas: Tinggi 🔴, Sedang 🟡, Rendah 🟢, atau Biasa ⚪.
- ☑️ **Mode To-Do List & Catatan Teks Bebas**:
  - Konversi instan antara catatan narasi dan to-do checklist dengan drag-and-drop reordering.
- 🎨 **12 Pilihan Warna Pastel & Tema Adaptif**:
  - Warna kartu pastel yang elegan untuk mode Terang (Light) dan Gelap (Dark).
  - Tampilan fleksibel: Masonry Grid 2 Kolom atau List 1 Kolom.
- 🔒 **Keamanan PIN & Tempat Sampah**:
  - Kunci catatan pribadi dengan 4-digit PIN.
  - Tempat sampah (Recycle Bin) untuk memulihkan catatan yang tidak sengaja terhapus.
- 📦 **Cadangan Data (Backup & Restore)**:
  - Ekspor dan impor data catatan dalam format JSON kapan saja.

---

## 🛠️ Teknologi yang Digunakan

- **Flutter SDK**: ^3.11.5 / Dart ^3.x
- **State Management**: `ChangeNotifier` / `ListenableBuilder`
- **Penyimpanan Lokal**: `shared_preferences`
- **Notifikasi Lokal**: `flutter_local_notifications` & `timezone`
- **Desain UI**: Material 3, Google Fonts (*Plus Jakarta Sans*), `flutter_staggered_grid_view`

---

## 🚀 Cara Menjalankan & Membangun APK

### Prasyarat
- Flutter SDK terpasang di sistem ([Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install))
- Android SDK & Java 17

### Menjalankan di Mode Debug
```bash
# Clone repository
git clone https://github.com/attaramadhani/APK-note.git
cd APK-note

# Pasang dependencies
flutter pub get

# Jalankan di emulator atau HP terhubung
flutter run
```

### Membangun Berkas APK Rilis
```bash
flutter build apk --release
```
Berkas APK rilis akan dihasilkan di: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Berkas APK Siap Pasang
Berkas APK versi siap pasang juga tersedia di root proyek: **`NoteCraft.apk`**.
