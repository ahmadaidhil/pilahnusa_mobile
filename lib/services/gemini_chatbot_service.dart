import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class GeminiChatbotService {
  static final GeminiChatbotService instance = GeminiChatbotService._init();
  GeminiChatbotService._init();

  static const List<String> _candidateModels = [
    'gemini-3.8-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  // Preset / Default API Key slot (can be populated directly or configured via UI)
  static const String? defaultApiKey = null;

  String? _userApiKey;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final savedKey = await DatabaseHelper.instance.getSetting('gemini_api_key');
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _userApiKey = savedKey.trim();
      } else if (defaultApiKey != null && defaultApiKey!.trim().isNotEmpty) {
        _userApiKey = defaultApiKey!.trim();
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[Chatbot] Failed to load saved API key: $e');
    }
  }

  Future<void> setApiKey(String key) async {
    _userApiKey = key.trim().isEmpty ? null : key.trim();
    try {
      await DatabaseHelper.instance.setSetting('gemini_api_key', _userApiKey ?? '');
    } catch (e) {
      debugPrint('[Chatbot] Failed to save API key to database: $e');
    }
  }

  String? get apiKey => _userApiKey;

  String _buildSystemPrompt(String userQuestion) {
    return '''
Anda adalah asisten edukasi cerdas PilahNusa AI yang membantu masyarakat Indonesia memahami pengelolaan, pemilahan, dan daur ulang sampah serta cara penggunaan aplikasi PilahNusa AI.

Informasi Aplikasi PilahNusa AI:
1. Panduan Penggunaan:
   - Di Beranda, pilih tombol "Scan Sekarang" untuk memotret objek sampah langsung via kamera, atau "Upload dari Galeri" untuk memilih foto.
   - Hasil deteksi AI on-device meliputi:
     * Kategori Sampah (Organik, Anorganik, B3) dan nama spesifiknya (contoh: Botol Plastik, Kardus, Sisa Makanan).
     * Tingkat Keyakinan AI (Confidence Level).
     * Waktu Terurai di alam (contoh: 450 tahun untuk botol plastik).
     * Potensi Nilai Ekonomi & tips daur ulang terperinci.
     * Video tutorial pemanfaatan ulang dari YouTube.
   - Semua hasil deteksi tersimpan otomatis di menu Riwayat (database lokal SQLite offline).
2. Tips Pemotretan Terbaik:
   - Pastikan pencahayaan cukup terang.
   - Fokuskan objek sampah di tengah bingkai dan hindari latar belakang yang terlalu ramai.

Aturan Menjawab:
- Berikan jawaban yang SINGKAT, PADAT, dan RAMAH langsung ke inti pertanyaan.
- Gunakan poin-poin (bullet points) atau daftar ringkas agar sangat nyaman dibaca di layar HP.
- Sampaikan jawaban dalam bentuk teks polos (plain text) yang bersih tanpa simbol markdown seperti tanda bintang (* atau **) untuk menebalkan/memiringkan.
- Hanya jawab pertanyaan seputar pengelolaan sampah, daur ulang, gaya hidup ramah lingkungan, dan penggunaan aplikasi PilahNusa AI.
- Jangan mengarang lokasi drop-point spesifik. Sarankan mengecek bank sampah terdekat atau kantor Dinas Lingkungan Hidup (DLH) setempat.

Pertanyaan pengguna:
$userQuestion
'''.trim();
  }

  Future<String> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Pertanyaan tidak boleh kosong.');
    }

    if (!_initialized) {
      await initialize();
    }

    final key = _userApiKey;
    if (key == null || key.isEmpty) {
      return _generateLocalAssistance(trimmedMessage);
    }

    final prompt = _buildSystemPrompt(trimmedMessage);
    String? lastError;
    bool isAuthError = false;

    for (final model in _candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': prompt}
                    ],
                  }
                ],
                'generationConfig': {
                  'temperature': 0.4,
                  'topP': 0.9,
                  'maxOutputTokens': 700,
                },
              }),
            )
            .timeout(const Duration(seconds: 12));

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final parts = data['candidates']?[0]?['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            String reply = parts.map((p) => p['text']?.toString() ?? '').join('\n').trim();
            // Clean markdown bold/italic asterisks for clean mobile display
            reply = reply.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
            reply = reply.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
            return reply;
          }
        } else if (response.statusCode == 403 || response.statusCode == 401) {
          isAuthError = true;
          lastError = data['error']?['message'] ?? 'API Key tidak valid atau telah diblokir.';
          break; // Stop attempting other models if the key itself is rejected
        } else {
          lastError = data['error']?['message'] ?? 'Error ${response.statusCode}';
          // Try next model (e.g. if 404 model not found/deprecated)
          continue;
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    // Fallback: If online call failed (e.g. invalid key or connection issue), provide helpful offline answer
    final localAnswer = _generateLocalAssistance(trimmedMessage);
    if (isAuthError) {
      return '''(Mode Offline PilahNusa AI)

$localAnswer

---
Catatan: API Key Gemini Anda tidak aktif atau dilaporkan bocor oleh Google. Anda dapat memperbarui API Key baru yang valid melalui tombol Kunci di pojok kanan atas.''';
    }

    if (lastError != null) {
      return '''(Mode Offline PilahNusa AI)

$localAnswer''';
    }

    return localAnswer;
  }

  String _generateLocalAssistance(String question) {
    final q = question.toLowerCase();

    // 1. Pembuangan di selokan / got / sungai / kali / laut / banjir
    if (q.contains('selokan') ||
        q.contains('got') ||
        q.contains('parit') ||
        q.contains('sungai') ||
        q.contains('kali') ||
        q.contains('laut') ||
        q.contains('banjir') ||
        q.contains('sembarangan')) {
      return '''TIDAK BOLEH membuang sampah di selokan, parit, got, atau sungai!

Dampak Berbahaya:
1. Memicu Banjir: Timbunan sampah menyumbat aliran air, terutama saat intensitas hujan tinggi.
2. Sumber Penyakit: Genangan air kotor menjadi sarang nyamuk Aedes aegypti (DBD), malaria, dan perkembangbiakan bakteri leptospirosis melalui tikus.
3. Pencemaran Air & Bau Busuk: Pembusukan sampah di saluran air menghasilkan gas metana dan bau menyengat yang mencemari air tanah warga.
4. Racun Mikroplastik: Sampah yang terbawa ke laut akan terpecah menjadi mikroplastik yang termakan ikan dan masuk ke rantai makanan manusia.

Langkah yang Benar:
• Buang sampah pada tempat sampah pilah (Organik, Anorganik, atau B3).
• Lakukan pembersihan got atau selokan secara berkala melalui kerja bakti warga.''';
    }

    // 2. Membakar sampah
    if (q.contains('bakar') || q.contains('membakar') || q.contains('asap')) {
      return '''JANGAN MEMBAKAR SAMPAH di pekarangan rumah atau ruang terbuka!

Bahaya Membakar Sampah:
1. Gas Beracun Dioksin & Furan: Pembakaran plastik melepaskan zat karsinogenik penyebab kanker dan kerusakan paru-paru.
2. Gangguan Pernapasan (ISPA): Asap pembakaran sangat berbahaya bagi anak-anak, lansia, dan penderita asma.
3. Risiko Kebakaran: Api pembakaran sampah dapat merembet ke bangunan atau lahan kering sekitar.

Solusi Alternatif yang Tepat:
• Sampah Organik (daun/ranting): Olah menjadi pupuk kompos atau kubur di lubang biopori.
• Sampah Anorganik: Kumpulkan dan salurkan ke Bank Sampah atau pengepul daur ulang.''';
    }

    // 3. Minyak jelantah
    if (q.contains('minyak') || q.contains('jelantah') || q.contains('goreng')) {
      return '''Pengelolaan Minyak Jelantah (Minyak Goreng Bekas):

Peringatan Penting:
• JANGAN PERNAH membuang minyak jelantah ke wastafel, kloset, atau selokan!
• Minyak akan membeku, melapisi pipa pembuangan, dan membentuk gumpalan keras (fatberg) yang menyumbat saluran air.

Cara Penanganan yang Benar:
1. Dinginkan sisa minyak setelah memasak.
2. Saring dari remah-remah makanan.
3. Simpan dalam wadah/botol tertutup (seperti botol air mineral bekas).
4. Setelah terkumpul banyak, setor ke Bank Sampah atau komunitas pengolah jelantah untuk diubah menjadi biodiesel atau lilin aromaterapi.''';
    }

    // 4. Styrofoam / gabus
    if (q.contains('styrofoam') || q.contains('sterofom') || q.contains('gabus')) {
      return '''Pengelolaan Sampah Styrofoam (Polistirena):

Karakteristik & Bahaya:
• Sangat sulit terurai secara alami di alam (membutuhkan lebih dari 500 tahun).
• Mengandung senyawa stirena yang berbahaya bagi kesehatan jika bersentuhan langsung dengan makanan panas atau berlemak.

Tips Penanganan:
1. Kurangi Penggunaan (Reduce): Bawa kotak makan atau wadah makanan sendiri saat membeli makanan di luar.
2. Pembersihan: Bersihkan sisa bumbu/minyak yang menempel sebelum dibuang.
3. Daur Ulang Kreatif: Styrofoam bersih dapat dilarutkan dengan minyak kayu putih atau aseton untuk dijadikan lem serbaguna atau pot bunga.''';
    }

    // 5. Popok / pampers / pembalut
    if (q.contains('popok') || q.contains('pampers') || q.contains('pembalut') || q.contains('residu')) {
      return '''Pengelolaan Sampah Popok Bayi & Pembalut:

Kategori: Sampah Residu (Non-Kompos)

Langkah Pembuangan Higienis:
1. Bersihkan kotoran padat terlebih dahulu ke dalam kloset dan siram hingga bersih.
2. Gulung popok/pembalut dengan rapi.
3. Bungkus rapat menggunakan kertas bekas atau kantong plastik kecil agar tidak memicu bau dan bakteri.
4. Buang ke tempat sampah residu (warna abu-abu/hitam).
5. JANGAN membuangnya ke kloset (menyebabkan septic tank mampet) atau ke selokan/sungai!''';
    }

    // 6. Sampah medis / masker / obat
    if (q.contains('medis') || q.contains('masker') || q.contains('obat') || q.contains('jarum')) {
      return '''Pengelolaan Limbah Medis & Obat-Obatan Rumah Tangga:

1. Masker Medis Bekas:
   • Potong/gunting tali masker sebelum dibuang agar tidak menjerat satwa atau didaur ulang secara ilegal oleh oknum.
   • Lipat dan masukkan ke wadah tertutup.

2. Obat Kadaluarsa:
   • Tablet/Kapsul: Keluarkan dari kemasan, hancurkan, campur dengan tanah atau ampas kopi, lalu buang ke tempat sampah tertutup.
   • Obat Cair/Sirup: Larutkan dengan banyak air dan buang ke saluran pembuangan, lalu rusak label botolnya.

3. Jarum Suntik / Benda Tajam:
   • Masukkan ke dalam wadah plastik keras (seperti botol deterjen) yang ditutup rapat dan beri label "Benda Tajam Medis" sebelum diserahkan ke Puskesmas.''';
    }

    // 7. Prinsip 3R (Reduce, Reuse, Recycle)
    if (q.contains('3r') || q.contains('reduce') || q.contains('reuse') || q.contains('recycle') || q.contains('prinsip')) {
      return '''Prinsip 3R dalam Pengelolaan Sampah:

1. Reduce (Mengurangi):
   • Kurangi timbulan sampah dari awal.
   • Contoh: Bawa tas belanja kain sendiri, gunakan tumbler air minum, tolak sedotan plastik sekali pakai.

2. Reuse (Menggunakan Kembali):
   • Manfaatkan kembali barang yang masih layak tanpa proses daur ulang rumit.
   • Contoh: Menggunakan toples selai untuk wadah bumbu, memanfaatkan baju bekas sebagai kain lap.

3. Recycle (Mendaur Ulang):
   • Mengolah sampah menjadi produk baru yang bernilai fungsional atau ekonomis.
   • Contoh: Mengolah sampah organik menjadi kompos, mencacah botol plastik PET menjadi bijih plastik daur ulang.''';
    }

    // 8. Bank Sampah / Nilai Ekonomi
    if (q.contains('bank sampah') || q.contains('jual') || q.contains('harga') || q.contains('uang') || q.contains('ekonomi')) {
      return '''Panduan Menjual Sampah ke Bank Sampah:

Sampah Bernilai Jual Tinggi:
• Botol Plastik PET bening (tanpa label & tutup): Rp 2.500 - Rp 4.500 / kg
• Kardus / Karton tebal: Rp 1.500 - Rp 2.500 / kg
• Kaleng Aluminium / Minuman soda: Rp 10.000 - Rp 15.000 / kg
• Kertas HVS / Buku tulis bekas: Rp 1.000 - Rp 2.000 / kg
• Tembaga & Kabel bekas: Rp 60.000 - Rp 80.000 / kg

Tips Agar Dihargai Mahal:
1. Pastikan sampah dalam keadaan bersih dan kering.
2. Lepaskan label merek dan tutup botol.
3. Pisahkan berdasarkan kelompok jenis material.''';
    }

    // 9. Organik / Kompos / Sisa Makanan
    if (q.contains('organik') || q.contains('makanan') || q.contains('sayur') || q.contains('buah') || q.contains('daun') || q.contains('kompos') || q.contains('biopori') || q.contains('maggot')) {
      return '''Sampah Organik adalah sampah dari bahan hayati yang dapat terurai alami oleh mikroorganisme.

Contoh Sampah Organik:
• Sisa makanan, nasi, sayuran, dan kulit buah
• Daun kering, ranting kecil, dan sisa tanaman
• Kulit telur dan ampas kopi/teh

Cara Pengolahan & Daur Ulang:
1. Pembuatan Kompos: Kumpulkan di komposter, campur rasio hijau (basah) dan cokelat (daun kering).
2. Lubang Resapan Biopori: Buat lubang tanah silindris untuk resapan air dan resapan kompos.
3. Eco-Enzyme: Fermentasikan kulit buah dengan gula aren dan air (rasio 3:1:10) selama 3 bulan.
4. Pakan Ternak / Maggot BSF: Olah sisa makanan sebagai pakan larva lalat tentara hitam berprotein tinggi.''';
    }

    // 10. Anorganik / Plastik / Botol / Kardus / Kertas
    if (q.contains('anorganik') || q.contains('plastik') || q.contains('botol') || q.contains('kardus') || q.contains('kertas') || q.contains('kaleng') || q.contains('kaca') || q.contains('kresek')) {
      return '''Sampah Anorganik adalah material buatan manusia yang tidak membusuk secara alami atau butuh ratusan tahun untuk terurai.

Waktu Terurai Sampah:
• Kantong kresek: 10 - 20 tahun
• Botol plastik (PET): 450 tahun
• Kaleng aluminium: 80 - 200 tahun
• Botol kaca: Hingga 1 juta tahun (hampir tidak pernah hancur di alam)

Langkah Pengelolaan Terbaik:
1. Bilas & Keringkan dari sisa kotoran atau minuman.
2. Remas botol plastik dan lipat kardus untuk menghemat ruang penyimpanan.
3. Pisahkan per kategori: plastik bening, plastik buram, kertas, dan logam.
4. Salurkan ke Bank Sampah terdekat.''';
    }

    // 11. B3 / Baterai / Lampu / Elektronik
    if (q.contains('b3') || q.contains('baterai') || q.contains('lampu') || q.contains('racun') || q.contains('elektronik') || q.contains('aki')) {
      return '''Sampah B3 (Bahan Berbahaya dan Beracun):

Contoh B3 Rumah Tangga:
• Baterai bekas dan aki motor/mobil
• Lampu neon (TL) dan bohlam bekas (mengandung uap merkuri)
• Botol aerosol bekas obat nyamuk atau cat semprot
• Wadah pembersih lantai, karbol, dan pestisida tanaman

Aturan Penanganan:
1. JANGAN PERNAH dicampur dengan sampah rumah tangga biasa.
2. JANGAN dibakar atau dihancurkan karena dapat meledak atau mengeluarkan gas beracun.
3. Simpan di kotak tertutup berlabel khusus dan serahkan ke drop box e-waste atau kantor Dinas Lingkungan Hidup.''';
    }

    // 12. Panduan Aplikasi & Fitur Scan
    if (q.contains('cara') || q.contains('scan') || q.contains('pakai') || q.contains('aplikasi') || q.contains('foto') || q.contains('kamera') || q.contains('riwayat')) {
      return '''Panduan Menggunakan Aplikasi PilahNusa AI:

1. Memindai Sampah:
   • Buka tab "Beranda" atau "Scan".
   • Tekan "Scan Sekarang" untuk membuka kamera langsung, atau "Galeri" untuk memilih foto.
   • Posisikan objek sampah di tengah frame dengan cahaya terang.
2. Hasil Klasifikasi AI:
   • Kategori Sampah (Organik, Anorganik, B3) & nama spesifiknya dari 10 kelas.
   • Persentase Keyakinan AI.
   • Estimasi waktu terurai di alam & potensi nilai ekonomis.
   • Tips penanganan serta video tutorial YouTube daur ulang.
3. Riwayat Pemindaian:
   • Semua pemindaian tersimpan otomatis di menu "Riwayat" secara offline menggunakan database SQLite.''';
    }

    // 13. Sapaan
    if (q.contains('halo') || q.contains('hai') || q.contains('pagi') || q.contains('siang') || q.contains('sore') || q.contains('malam') || q.contains('assalam') || q.contains('siapa')) {
      return '''Halo! Senang bisa menyapa Anda.

Saya adalah asisten edukasi cerdas PilahNusa AI. Anda dapat menanyakan apa saja seputar:
• Bolehkah membuang sampah di selokan atau membakar sampah?
• Cara memilah sampah organik, anorganik, dan limbah B3
• Tips membuat kompos, biopori, dan eco-enzyme
• Cara mengelola minyak jelantah, styrofoam, dan sampah medis
• Panduan lengkap menggunakan fitur scan PilahNusa AI

Ada yang ingin Anda tanyakan seputar lingkungan atau sampah hari ini?''';
    }

    // 14. Ucapan terima kasih
    if (q.contains('makasih') || q.contains('terima kasih') || q.contains('thanks')) {
      return '''Sama-sama! Senang bisa membantu Anda menjaga kebersihan dan kelestarian lingkungan.

Mari bersama-sama wujudkan Indonesia bebas sampah dengan membiasakan memilah sampah dari rumah! Jika ada hal lain yang ingin Anda ketahui, tanyakan saja kapan pun.''';
    }

    // 15. Default Edukatif
    return '''Untuk mengelola sampah secara bijak, ikuti 3 kaidah utama PilahNusa AI:

1. Pilah dari Sumbernya:
   • Sampah Organik (sisa makanan, sayur, buah, daun) untuk dijadikan kompos.
   • Sampah Anorganik (botol plastik, kardus, kaleng, kaca) untuk didaur ulang atau disetor ke Bank Sampah.
   • Sampah B3 (baterai, lampu, obat kadaluarsa, botol racun) untuk dipisahkan di wadah khusus.

2. Kaidah Kebersihan:
   • Bersihkan dan keringkan wadah anorganik sebelum disimpan agar tidak bau dan bernilai jual tinggi.

3. Larangan Lingkungan:
   • JANGAN membuang sampah ke selokan/sungai (memicu banjir dan sarang penyakit).
   • JANGAN membakar sampah (menghasilkan gas beracun dioksin).

Silakan tanyakan hal spesifik seperti "apakah bisa membuang sampah di selokan", "cara mengolah minyak jelantah", atau "tips membuat kompos"!''';
  }
}
