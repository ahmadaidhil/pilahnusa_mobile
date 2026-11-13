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

  String? _userApiKey;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final savedKey = await DatabaseHelper.instance.getSetting('gemini_api_key');
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _userApiKey = savedKey.trim();
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

    if (q.contains('organik') || q.contains('makanan') || q.contains('sayur') || q.contains('buah') || q.contains('daun') || q.contains('kompos')) {
      return '''Sampah Organik adalah sampah yang berasal dari sisa makhluk hidup dan dapat terurai secara alami oleh mikroorganisme.

Contoh Sampah Organik:
• Sisa makanan, nasi, sayuran, dan kulit buah
• Daun kering, ranting kecil, dan sisa tanaman
• Kulit telur dan ampas kopi/teh

Cara Pengolahan & Daur Ulang:
1. Pembuatan Kompos: Kumpulkan di wadah kompos dan campur dengan tanah atau sekam.
2. Eco-Enzyme: Fermentasikan kulit buah dengan gula dan air untuk cairan pembersih serbaguna.
3. Pakan Ternak/Maggot BSF: Olah sisa makanan sebagai pakan larva Black Soldier Fly berprotein tinggi.
4. Tiriskan air sebelum dibuang agar tidak menimbulkan bau tidak sedap.''';
    }

    if (q.contains('anorganik') || q.contains('plastik') || q.contains('botol') || q.contains('kardus') || q.contains('kertas') || q.contains('kaleng') || q.contains('kaca') || q.contains('kresek')) {
      return '''Sampah Anorganik adalah sampah dari material buatan manusia yang tidak dapat membusuk secara alami atau membutuhkan waktu ratusan tahun untuk terurai.

Waktu Terurai Sampah:
• Kantong plastik: 10 - 20 tahun
• Botol plastik (PET): 450 tahun
• Kaleng aluminium: 80 - 200 tahun
• Kaca: Hingga 1 juta tahun (atau tidak terurai sama sekali)

Langkah Pengelolaan Terbaik (Prinsip 3R):
1. Bersihkan & Keringkan: Bilas botol atau wadah dari sisa cairan/makanan.
2. Pipihkan / Ringkas: Remas botol plastik dan lipat kardus untuk menghemat ruang tempat sampah.
3. Pisahkan berdasarkan jenis: Pisahkan kertas, kardus, plastik bening, dan logam.
4. Salurkan ke Bank Sampah: Sampah anorganik memiliki nilai ekonomis untuk didaur ulang.''';
    }

    if (q.contains('b3') || q.contains('baterai') || q.contains('lampu') || q.contains('racun') || q.contains('obat') || q.contains('elektronik')) {
      return '''Sampah B3 (Bahan Berbahaya dan Beracun) adalah limbah yang mengandung zat kimia berbahaya, mudah terbakar, meledak, atau beracun bagi manusia dan lingkungan.

Contoh Sampah B3 Rumah Tangga:
• Baterai bekas dan aki
• Lampu neon / LED rusak
• Botol aerosol (obat nyamuk, hairspray)
• Obat-obatan kadaluarsa
• Wadah deterjen keras, pembersih lantai, dan pestisida

Cara Penanganan Khusus:
1. JANGAN PERNAH dicampur dengan sampah organik atau anorganik.
2. JANGAN dibakar atau dihancurkan karena dapat melepaskan gas beracun.
3. Simpan sementara di wadah tertutup yang aman dan kering.
4. Setorkan ke tempat penampungan sampah B3 khusus (drop point e-waste) atau Dinas Lingkungan Hidup (DLH) setempat.''';
    }

    if (q.contains('cara') || q.contains('scan') || q.contains('pakai') || q.contains('aplikasi') || q.contains('foto') || q.contains('kamera')) {
      return '''Panduan Menggunakan Aplikasi PilahNusa AI:

1. Buka tab "Beranda" atau tab "Scan" di bagian bawah.
2. Pilih "Scan Sekarang" untuk memotret objek sampah langsung dengan kamera, atau "Upload dari Galeri".
3. Pastikan objek sampah berada di tengah bingkai dan pencahayaan terang.
4. AI on-device akan langsung mengklasifikasikan sampah ke salah satu dari 10 kategori.
5. Anda akan mendapatkan:
   • Kategori sampah (Organik, Anorganik, B3)
   • Persentase akurasi AI
   • Waktu terurai di alam
   • Potensi nilai ekonomi dan tips daur ulang
   • Video tutorial YouTube terkait
6. Semua hasil pemindaian tersimpan rapi dan dapat ditinjau kembali di tab "Riwayat".''';
    }

    if (q.contains('halo') || q.contains('hai') || q.contains('pagi') || q.contains('siang') || q.contains('sore') || q.contains('malam') || q.contains('assalamualaikum')) {
      return '''Halo! Senang bisa menyapa Anda.

Saya adalah asisten edukasi PilahNusa AI. Anda dapat menanyakan apa saja seputar:
• Cara memilah sampah organik, anorganik, dan B3
• Waktu penguraian sampah di alam
• Tips pembuatan kompos dan daur ulang kreatif
• Cara menggunakan fitur scan aplikasi PilahNusa AI

Ada yang ingin Anda tanyakan seputar pemilahan sampah hari ini?''';
    }

    return '''PilahNusa AI siap membantu Anda dalam memilah dan mengelola sampah secara bijak.

Topik yang dapat Anda tanyakan:
• "Bagaimana cara mengolah sampah organik?"
• "Berapa lama botol plastik terurai?"
• "Apa saja yang termasuk limbah B3?"
• "Bagaimana cara kerja scan di aplikasi ini?"

Silakan ajukan pertanyaan Anda seputar pemilahan sampah!''';
  }
}
