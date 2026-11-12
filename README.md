# PilahNusa AI Mobile (Flutter & SQLite)

Aplikasi mobile berbasis **Flutter (Dart)** dengan **database lokal SQLite** dan **Machine Learning TensorFlow Lite (TFLite) On-Device**, dikonversi dan diselaraskan secara persis dari repositori web [PilahNusa-AI](https://github.com/milen06/PilahNusa-AI).

---

## 📱 Ringkasan Proyek

PilahNusa AI Mobile membantu masyarakat Indonesia memilah sampah melalui foto secara cerdas, cepat, dan offline. Pengguna dapat memotret atau mengunggah foto sampah, lalu model Machine Learning on-device akan mengklasifikasikan jenis sampah ke dalam 10 kategori spesifik (Organik, Anorganik, dan B3) serta menampilkan panduan pembuangan, tips daur ulang, waktu terurai di alam, nilai ekonomi, dan tutorial kreatif YouTube.

Semua riwayat pemindaian disimpan secara persisten di dalam **database lokal SQLite**. Aplikasi juga dilengkapi asisten edukasi **Chatbot berbasis Gemini API** dan profil lengkap tim pengembang Capstone **CC26-PSU246** (Coding Camp 2026 didukung oleh DBS Foundation).

---

## 🧠 Machine Learning (Sama Persis dengan Versi Asli)

Model Machine Learning telah dikonversi langsung dari bobot graf TensorFlow.js (`model.json` dan 34 file shard bobot `.bin`) menjadi format **TensorFlow Lite (`waste_classifier.tflite`)** tanpa kehilangan bobot latih:

- **Arsitektur Dasar**: MobileNetV2 (Pre-trained ImageNet)
- **Ukuran Input**: `224 x 224 x 3` (RGB normalized [0.0, 1.0])
- **Layer Klasifikasi**:
  - `Dropout(0.2)`
  - `Flatten()` (output: 62,720)
  - `BatchNormalization()`
  - `Dense(512, activation='relu')`
  - `BatchNormalization()`
  - `Dropout(0.2)`
  - `Dense(256, activation='relu')`
  - `BatchNormalization()`
  - `Dropout(0.2)`
  - `Dense(128, activation='relu')`
  - `Dropout(0.2)`
  - `Dense(10, activation='softmax')`
- **10 Kelas Sampah yang Dikenali**:
  1. `Botol Plastik` (Anorganik)
  2. `Kaca` (Anorganik)
  3. `Kardus dan Kertas` (Anorganik)
  4. `Makanan Sisa` (Organik)
  5. `Metal` (Anorganik)
  6. `Pakaian` (Anorganik)
  7. `Plastik` (Anorganik)
  8. `Sisa Buah dan Sayur` (Organik)
  9. `Tumbuhan` (Organik)
  10. `battery` / Baterai (B3)

---

## 🗄️ Database SQLite

Menggunakan package `sqflite` (dan `sqflite_common_ffi` untuk pengujian/desktop):

- **Tabel `scan_history`**:
  - `id` (TEXT PRIMARY KEY)
  - `timestamp` (TEXT)
  - `image_path` (TEXT)
  - `image_base64` (TEXT)
  - `user_feedback` (TEXT)
  - `name` (TEXT)
  - `category` (TEXT - Organik, Anorganik, B3)
  - `confidence` (REAL)
  - `description` (TEXT)
  - `disposal_guide` (TEXT)
  - `environmental_impact` (TEXT)
  - `decomposition_time` (TEXT)
  - `economic_value` (TEXT)
  - `recycling_tips` (TEXT - JSON)
  - `recycling_potential` (TEXT - JSON)
  - `youtube_tutorials` (TEXT - JSON)
- **Tabel `chat_messages`**:
  - Menyimpan percakapan tanya jawab dengan Asisten Edukasi PilahNusa AI.

---

## 🌟 Fitur Utama

1. **Beranda (Home)**:
   - Sambutan & panduan ringkas 3 langkah.
   - Statistik riwayat pemindaian real-time dari database SQLite (Total, Organik, Anorganik, B3).
   - Akses cepat ke pemindaian kamera dan galeri.
2. **Pemindai AI (Scan)**:
   - Viewfinder panduan kamera dengan animasi pemindaian real-time.
   - Pilihan kamera langsung atau unggah foto dari galeri.
   - Inferensi on-device cepat via TFLite.
3. **Hasil Klasifikasi (Result)**:
   - Badge kategori (Organik: Hijau, Anorganik: Biru, B3: Merah).
   - Indikator persentase keyakinan AI (*Confidence Bar*).
   - Waktu terurai di alam & nilai ekonomi material.
   - Bahaya dampak lingkungan jika tidak dipilah.
   - Panduan pembuangan yang aman.
   - Tips daur ulang & daftar potensi daur ulang.
   - Rekomendasi video tutorial YouTube yang dapat dibuka langsung.
   - Formulir umpan balik akurasi deteksi.
   - Fitur bagikan hasil (*Share*).
4. **Riwayat Pemindaian (History)**:
   - Filter berdasarkan kategori (Semua, Organik, Anorganik, B3).
   - Fitur pencarian instan.
   - Swipe atau klik untuk menghapus per item atau hapus semua dengan konfirmasi.
5. **Panduan Pemilahan (Guide)**:
   - Edukasi mendalam sampah Organik, Anorganik, dan B3.
   - Penerapan prinsip 3R (*Reduce, Reuse, Recycle*).
   - Panduan Bank Sampah.
6. **Tanya AI (Chatbot)**:
   - Asisten edukasi pemilahan sampah yang terhubung ke Gemini API (`gemini-2.5-flash`).
   - Prompt sistem khusus yang memahami konteks aplikasi dan profil pengembang.
   - Dukungan konfigurasi API Key langsung dari aplikasi.
7. **Profil Tim Pengembang (Team)**:
   - Profil 6 anggota tim Capstone CC26-PSU246 lengkap dengan foto asli, universitas, peran, dan kutipan inspiratif.
   - Tautan ke Dashboard Dataset Streamlit.

---

## 👥 Tim Pengembang (CC26-PSU246)

| Nama | ID Siswa | Peran | Universitas |
| --- | --- | --- | --- |
| **Irdan Guntara** | CACC246D6Y0874 | Project Manager & AI Engineer | Universitas Kuningan |
| **Galih Rizaldy** | CACC246D6Y0535 | AI Engineer | Universitas Kuningan |
| **Ema Maleni** | CFCC174D6X0683 | Full-Stack Web & Mobile Developer | Universitas Primakara |
| **Nayarah Atmawardani** | CFCC362D6X1422 | Full-Stack Web & Mobile Developer | Universitas Sulawesi Barat |
| **Ryan Dwi Antoni** | CDCC284D6Y1670 | Data Scientist | Universitas Negeri Surabaya |
| **Gisca Oktavia Ramadhani** | CDCC246D6X2496 | Data Scientist | Universitas Kuningan |

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Masuk ke Direktori Proyek

```bash
cd C:\Users\ASUS\.gemini\antigravity\scratch\pilahnusa_mobile
```

### 2. Mengambil Dependensi

```bash
flutter pub get
```

### 3. Menjalankan Pengujian (Testing)

```bash
flutter test
```

### 4. Menjalankan Aplikasi

Jalankan pada emulator Android, device fisik, atau desktop:

```bash
flutter run
```
