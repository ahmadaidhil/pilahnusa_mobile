import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiChatbotService {
  static final GeminiChatbotService instance = GeminiChatbotService._init();
  GeminiChatbotService._init();

  static const String _defaultModel = 'gemini-2.5-flash';
  String? _userApiKey;

  void setApiKey(String key) {
    _userApiKey = key.trim();
  }

  String? get apiKey => _userApiKey;

  String _buildSystemPrompt(String userQuestion) {
    return '''
Anda adalah asisten edukasi PilahNusa AI yang membantu masyarakat Indonesia memahami pengelolaan sampah, cara penggunaan aplikasi PilahNusa AI, serta profil pengembang.

Informasi Penting Aplikasi PilahNusa AI:
1. Langkah Penggunaan Utama:
   - Akses PilahNusa AI Mobile di smartphone Anda. Di halaman Beranda, sambutan edukasi berbunyi "Scan sampahmu dan pelajari cara pengelolaannya".
   - Pilih Metode Pemindaian dengan menekan tombol:
     * "Scan Sekarang" untuk membuka kamera langsung dan memotret objek sampah.
     * "Upload dari Galeri" untuk memilih foto sampah statis dari penyimpanan perangkat.
   - Hasil & Panduan Edukasi yang akan ditampilkan meliputi:
     * Kategori Sampah (Organik, Anorganik, B3) beserta nama klasifikasinya (contoh: "Sisa buah dan sayur", "Botol Plastik").
     * Tingkat Keyakinan AI (Confidence Level) dalam bentuk persentase.
     * Waktu Terurai di alam (contoh: 450 tahun untuk botol plastik).
     * Nilai Ekonomi (Tinggi, Sedang, Rendah).
     * Cara Pembuangan dan tips daur ulang yang tepat serta video tutorial YouTube.
   - Navigasi Riwayat: Pengguna dapat menuju menu "Riwayat" di navigasi bawah untuk meninjau kembali riwayat hasil pemindaian sampah yang disimpan secara offline di SQLite database.
2. Tips Pemotretan / Deteksi Paling Akurat:
   - Pastikan pencahayaan cukup terang saat memotret objek.
   - Fokuskan kamera hanya pada satu jenis sampah dalam satu bingkai.
   - Hindari latar belakang (background) yang terlalu ramai.
   - Pastikan foto tajam dan tidak kabur (blur).
3. Profil Pengembang & Capstone Project:
   - Didirikan dan dikembangkan oleh tim capstone dengan ID CC26-PSU246 untuk program Coding Camp 2026 yang didukung oleh DBS Foundation.
   - Tim pengembang terdiri dari 6 anggota dengan peran:
     * Irdan Guntara (Project Manager & AI Engineer) - Universitas Kuningan
     * Galih Rizaldy (AI Engineer) - Universitas Kuningan
     * Ema Maleni (Full-Stack Web Developer) - Universitas Primakara
     * Nayarah Atmawardani (Full-Stack Web Developer) - Universitas Sulawesi Barat
     * Ryan Dwi Antoni (Data Scientist) - Universitas Negeri Surabaya
     * Gisca Oktavia Ramadhani (Data Scientist) - Universitas Kuningan

Aturan Menjawab:
- Berikan jawaban yang SINGKAT, PADAT, dan JELAS langsung ke inti pertanyaan.
- Gunakan poin-poin (bullet points) atau daftar ringkas agar sangat mudah dibaca di layar ponsel.
- Selalu hapus dan jangan pernah gunakan simbol format tambahan atau markdown seperti tanda bintang (*) atau bintang ganda (**) untuk menebalkan atau memiringkan kata. Sampaikan jawaban dalam bentuk teks polos (plain text) yang bersih tanpa simbol pemformatan tersebut.
- Hanya jawab pertanyaan seputar pengelolaan/pemilahan sampah, penggunaan/tips aplikasi PilahNusa AI, atau profil pengembang (Tim CC26-PSU246).
- Jika ditanya di luar topik di atas, jawab dengan sopan bahwa Anda adalah asisten edukasi PilahNusa AI dan hanya melayani edukasi pemilahan sampah serta aplikasi PilahNusa AI.
- Jangan mengarang lokasi drop-point spesifik. Sarankan mengecek bank sampah terdekat atau DLH setempat.

Pertanyaan pengguna:
$userQuestion
'''.trim();
  }

  Future<String> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Pertanyaan tidak boleh kosong.');
    }

    final key = _userApiKey;
    if (key == null || key.isEmpty) {
      // Provide an informative, friendly local response if API key is not yet configured
      return _generateLocalAssistance(trimmedMessage);
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$key',
    );

    final prompt = _buildSystemPrompt(trimmedMessage);

    final response = await http.post(
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
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final errorMsg = data['error']?['message'] ?? 'Gagal memproses pertanyaan ke Gemini.';
      throw Exception(errorMsg);
    }

    final parts = data['candidates']?[0]?['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini tidak mengembalikan jawaban. Silakan coba lagi.');
    }

    final reply = parts.map((p) => p['text']?.toString() ?? '').join('\n').trim();
    return reply;
  }

  String _generateLocalAssistance(String question) {
    final q = question.toLowerCase();

    if (q.contains('tim') || q.contains('pengembang') || q.contains('capstone') || q.contains('pembuat')) {
      return '''PilahNusa AI dikembangkan oleh Tim Capstone CC26-PSU246 Program Coding Camp 2026 didukung oleh DBS Foundation:

1. Irdan Guntara - Project Manager & AI Engineer (Universitas Kuningan)
2. Galih Rizaldy - AI Engineer (Universitas Kuningan)
3. Ema Maleni - Full-Stack Web Developer (Universitas Primakara)
4. Nayarah Atmawardani - Full-Stack Web Developer (Universitas Sulawesi Barat)
5. Ryan Dwi Antoni - Data Scientist (Universitas Negeri Surabaya)
6. Gisca Oktavia Ramadhani - Data Scientist (Universitas Kuningan)''';
    }

    if (q.contains('organik')) {
      return '''Sampah Organik adalah sampah yang berasal dari sisa makhluk hidup dan mudah membusuk secara alami.

Contoh:
- Sisa makanan, nasi, sayur dan buah
- Daun gugur, ranting, dan rumput

Cara Pengolahan:
- Olah menjadi kompos tanaman
- Tiriskan air sebelum dibuang
- Pisahkan dari plastik dan kemasan
- Buat eco-enzyme untuk sisa kulit buah''';
    }

    if (q.contains('anorganik') || q.contains('plastik') || q.contains('botol')) {
      return '''Sampah Anorganik adalah sampah dari bahan non-hayati atau proses industri yang sulit terurai secara alami.

Contoh:
- Botol dan kemasan plastik (terurai 100-500 tahun)
- Kardus, kertas, kaleng logam, dan kaca

Cara Pengolahan:
- Kosongkan dan bilas dari sisa makanan/minuman
- Pipihkan botol plastik atau kardus untuk hemat ruang
- Kumpulkan dan salurkan ke Bank Sampah atau pengepul daur ulang''';
    }

    if (q.contains('b3') || q.contains('baterai')) {
      return '''Sampah B3 (Bahan Berbahaya dan Beracun) adalah limbah yang mengandung zat beracun dan dapat membahayakan kesehatan serta lingkungan.

Contoh:
- Baterai bekas, lampu neon, botol aerosol, aki, obat kadaluarsa

Cara Penanganan:
- Jangan campur dengan sampah organik atau anorganik!
- Simpan di wadah kering tertutup (misal botol kaca)
- Bawa ke drop-point khusus limbah B3 atau Dinas Lingkungan Hidup terdekat''';
    }

    if (q.contains('cara') || q.contains('scan') || q.contains('pakai') || q.contains('aplikasi')) {
      return '''Cara menggunakan PilahNusa AI Mobile:

1. Buka menu Beranda atau tab Scan.
2. Pilih Scan Kamera untuk mengambil foto langsung, atau Upload dari Galeri.
3. Pastikan objek sampah berada di tengah bingkai dengan pencahayaan terang.
4. AI akan mendeteksi jenis sampah secara offline di ponsel Anda.
5. Anda akan mendapatkan kategori sampah, persentase keyakinan, waktu terurai, panduan pembuangan, dan tips daur ulang.
6. Hasil pemindaian tersimpan secara otomatis di menu Riwayat (SQLite).''';
    }

    return '''Halo! Saya asisten edukasi PilahNusa AI.

Anda dapat menanyakan seputar:
- Cara memilah sampah organik, anorganik, dan B3
- Panduan daur ulang dan waktu terurai sampah
- Tips penggunaan aplikasi PilahNusa AI Mobile
- Profil pengembang Tim PilahNusa AI (CC26-PSU246)

Catatan: Untuk mengaktifkan respon cerdas penuh berbasis model Gemini 2.5 Flash, Anda dapat memasukkan Gemini API Key melalui ikon Pengaturan di kanan atas.''';
  }
}

