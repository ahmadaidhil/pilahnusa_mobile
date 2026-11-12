// ignore_for_file: constant_identifier_names, non_constant_identifier_names

class YoutubeTutorial {
  final String label;
  final String url;

  const YoutubeTutorial({
    required this.label,
    required this.url,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'url': url,
      };

  factory YoutubeTutorial.fromMap(Map<String, dynamic> map) => YoutubeTutorial(
        label: map['label'] as String? ?? '',
        url: map['url'] as String? ?? '',
      );
}

class WasteClassData {
  final String name;
  final String category;
  final String description;
  final List<String> recyclingPotential;
  final String disposalGuide;
  final String environmentalImpact;
  final String decompositionTime;
  final String economicValue;
  final List<String> recyclingTips;
  final List<YoutubeTutorial> youtubeTutorials;

  const WasteClassData({
    required this.name,
    required this.category,
    required this.description,
    required this.recyclingPotential,
    required this.disposalGuide,
    required this.environmentalImpact,
    required this.decompositionTime,
    required this.economicValue,
    required this.recyclingTips,
    required this.youtubeTutorials,
  });
}

// 10 Class Labels matching model output indices 0..9
const List<String> CLASS_LABELS = [
  'Botol Plastik',
  'Kaca',
  'Kardus dan Kertas',
  'Makanan Sisa',
  'Metal',
  'Pakaian',
  'Plastik',
  'Sisa Buah dan Sayur',
  'Tumbuhan',
  'battery',
];

// Single source of truth for all waste data - exactly matching PilahNusa-AI repo
final Map<String, WasteClassData> WASTE_DATA_MAP = {
  'Botol Plastik': const WasteClassData(
    name: 'Botol Plastik',
    category: 'anorganik',
    description:
        'Botol plastik jenis PET (Polyethylene Terephthalate) yang umum digunakan untuk minuman kemasan dan dapat didaur ulang.',
    recyclingPotential: [
      'Tali',
      'Pot tanaman gantung',
      'Wadah alat tulis/pernak pernik',
      'Toples',
      'Sapu',
      'Cutting board'
    ],
    disposalGuide: 'Kosongkan isinya, bilas, lepaskan label, dan remas botolnya.',
    environmentalImpact: 'Menjadi mikroplastik yang masuk ke rantai makanan manusia.',
    decompositionTime: '450 Tahun',
    economicValue: 'Tinggi',
    recyclingTips: [
      'Kosongkan dan bilas sebelum dibuang',
      'Pisahkan tutup botol dari badan botol',
      'Remas botol untuk hemat ruang',
      'Kumpulkan dan jual ke bank sampah',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Tali', url: 'https://youtu.be/tGRLeQ1LS-E?si=o6InnJFAsJZw_nvP'),
      YoutubeTutorial(label: 'Pot Tanaman', url: 'https://youtube.com/shorts/xelbGICjK-M?si=n-wlxuvsC0TTYaJY'),
      YoutubeTutorial(label: 'Wadah Alat Tulis', url: 'https://youtu.be/RS73u9OFf2I?si=6bfNkfXrNW2Jz3pc'),
      YoutubeTutorial(label: 'Toples', url: 'https://youtu.be/N_H1W739pJU?si=fFMpHAGTaRCoGDKi'),
      YoutubeTutorial(label: 'Sapu', url: 'https://youtu.be/2OeZAS-wJCA?si=c18SNvUq6D2kombe'),
      YoutubeTutorial(label: 'Cutting Board', url: 'https://youtu.be/jx2B55YG4SY?si=LlasYVX7kWAxQTZF'),
    ],
  ),
  'Kaca': const WasteClassData(
    name: 'Kaca',
    category: 'anorganik',
    description:
        'Pecahan kaca atau botol kaca yang bisa didaur ulang tanpa batas tanpa kehilangan kualitas materialnya.',
    recyclingPotential: ['Toples', 'Kerajinan', 'Wadah', 'Lampu minyak'],
    disposalGuide:
        'Pastikan tidak pecah saat pembuangan. Jika pecah, bungkus dengan koran agar tidak melukai petugas. Rebus botol dalam air mendidih untuk mensterilkan sebelum dipakai ulang.',
    environmentalImpact: 'Melukai hewan dan manusia; tidak bisa hancur secara alami.',
    decompositionTime: 'Selamanya',
    economicValue: 'Sedang',
    recyclingTips: [
      'Pastikan kaca tidak pecah saat disimpan',
      'Bungkus pecahan dengan koran tebal',
      'Rebus botol untuk sterilisasi sebelum dipakai ulang',
      'Bawa ke bank sampah atau pengepul kaca',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Toples', url: 'https://youtu.be/pja8HgSC6jU?si=b3vOkRYT--FhFHPU'),
      YoutubeTutorial(label: 'Kerajinan', url: 'https://youtu.be/ZNHpKYy2lBw?si=cMlGJYlDopheL39e'),
      YoutubeTutorial(label: 'Wadah', url: 'https://youtube.com/shorts/KS-g7jLhQQs?si=CgMwmn-LP0TqctKk'),
      YoutubeTutorial(label: 'Lampu Minyak', url: 'https://youtube.com/shorts/CMjAB4uFfYg?si=lUbYhsatUrRAgZYq'),
    ],
  ),
  'Kardus dan Kertas': const WasteClassData(
    name: 'Kardus dan Kertas',
    category: 'anorganik',
    description:
        'Kertas dan kardus bekas yang mudah didaur ulang dan memiliki nilai ekonomi cukup baik.',
    recyclingPotential: ['Wallpaper dinding', 'Lemari', 'Bahan kerajinan tangan', 'Bungkus gorengan', 'Tote bag'],
    disposalGuide: 'Wajib kering. Lipat/pipihkan untuk menghemat ruang penyimpanan.',
    environmentalImpact: 'Jika basah, kualitas serat rusak dan tidak bisa didaur ulang.',
    decompositionTime: '2-5 Bulan',
    economicValue: 'Tinggi',
    recyclingTips: [
      'Pastikan kering sebelum disimpan',
      'Lipat pipih untuk hemat ruang',
      'Lepas selotip dan staples',
      'Jual ke pengepul kertas atau bank sampah',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Wallpaper Dinding', url: 'https://youtu.be/xE0ik8bWc3c?si=jn81gsbWdtBw5vqy'),
      YoutubeTutorial(label: 'Lemari', url: 'https://youtu.be/dNuF2uP86PU?si=bx1MC8maAUsy6d8y'),
      YoutubeTutorial(label: 'Kerajinan Tangan', url: 'https://youtu.be/--jaFz8e-3g?si=srg9Pm_IRt6hsKkK'),
      YoutubeTutorial(label: 'Bungkus Gorengan', url: 'https://youtu.be/RaZf1OTXGEc?si=JbyNdMQC4yut30OE'),
      YoutubeTutorial(label: 'Tote Bag', url: 'https://youtu.be/BgCUD6bxiGU?si=YBYGvIdgMbaXqx7N'),
    ],
  ),
  'Makanan Sisa': const WasteClassData(
    name: 'Makanan Sisa',
    category: 'organik',
    description:
        'Sisa makanan konsumsi yang mudah membusuk dan merupakan bahan baku utama kompos.',
    recyclingPotential: ['Kompos', 'Pakan ternak', 'Bioplastik'],
    disposalGuide: 'Pisahkan dari plastik pembungkus. Jangan biarkan terlalu berair.',
    environmentalImpact: 'Menghasilkan gas metana (CH4) yang menyebabkan efek rumah kaca.',
    decompositionTime: '1-4 Minggu',
    economicValue: 'Rendah',
    recyclingTips: [
      'Pisahkan dari plastik pembungkus',
      'Tiriskan air berlebih',
      'Jadikan kompos atau pakan ternak',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Kompos', url: 'https://youtu.be/PkYgN3xfJ2I?si=-Ef6FKhEqyUhzMnj'),
      YoutubeTutorial(label: 'Bioplastik', url: 'https://youtu.be/4RGQzvvMFpc?si=6hdaw8rkGm-tduZc'),
    ],
  ),
  'Metal': const WasteClassData(
    name: 'Metal',
    category: 'anorganik',
    description:
        'Kaleng bekas minuman, makanan, atau logam lainnya yang memiliki nilai ekonomi tinggi dan dapat didaur ulang berkali-kali.',
    recyclingPotential: ['Gelas', 'Wadah', 'Celengan', 'Pot', 'Asbak'],
    disposalGuide:
        'Bilas sisa makanan/minuman yang menempel dan amplas bagian pinggir yang tajam agar tidak melukai tangan.',
    environmentalImpact: 'Karatnya dapat mencemari unsur hara dalam tanah.',
    decompositionTime: '50-200 Tahun',
    economicValue: 'Tinggi',
    recyclingTips: [
      'Cuci bersih dan keringkan sebelum dikumpulkan',
      'Amplas pinggiran tajam agar aman',
      'Pisahkan aluminium dan baja',
      'Jual ke pengepul logam',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Gelas', url: 'https://youtube.com/shorts/AX2l6qVeKcw?si=RgixO6axNQqP_ujv'),
      YoutubeTutorial(label: 'Wadah', url: 'https://youtu.be/MPIOOmnve-8?si=edM7Zxyx64b94lAX'),
      YoutubeTutorial(label: 'Celengan', url: 'https://youtube.com/shorts/sw45qEk_ZnQ?si=ebUWb8s9-p-cq3SE'),
      YoutubeTutorial(label: 'Pot', url: 'https://youtube.com/shorts/G0_KFWwEmuE?si=tKxK7z0BDDYjTxIm'),
      YoutubeTutorial(label: 'Asbak', url: 'https://youtube.com/shorts/XDzgPWdMNu4?si=k-SUK18VSyadxVW1'),
    ],
  ),
  'Pakaian': const WasteClassData(
    name: 'Pakaian',
    category: 'anorganik',
    description:
        'Pakaian bekas, kain, atau produk tekstil lainnya yang dapat didaur ulang menjadi lap, kerajinan tangan, atau serat kain baru.',
    recyclingPotential: ['Lap pembersih', 'Tas belanja (Tote bag)', 'Keset kaki', 'Isian bantal/boneka', 'Kerajinan tangan'],
    disposalGuide:
        'Pastikan pakaian dalam kondisi bersih dan kering. Pisahkan pakaian layak pakai untuk didonasikan, dan pakaian rusak untuk didaur ulang.',
    environmentalImpact:
        'Serat sintetis (seperti poliester) dapat mencemari lingkungan dengan mikroplastik jika terurai perlahan.',
    decompositionTime: '20-200 Tahun',
    economicValue: 'Sedang',
    recyclingTips: [
      'Pakaian layak pakai sebaiknya didonasikan',
      'Potong pakaian rusak menjadi kain lap untuk menghemat penggunaan tisu',
      'Gunakan kain perca untuk kerajinan tangan kreatif',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Tote Bag dari Baju Bekas', url: 'https://youtu.be/wQc7G81H0B8'),
      YoutubeTutorial(label: 'Keset Kaki dari Kaos', url: 'https://youtu.be/shm_6U0vYfA'),
    ],
  ),
  'Plastik': const WasteClassData(
    name: 'Plastik',
    category: 'anorganik',
    description:
        'Sampah plastik umum seperti kantong plastik, sedotan, kemasan makanan, atau produk plastik lainnya yang sulit terurai.',
    recyclingPotential: ['Ecobrick', 'Pot tanaman', 'Kerajinan tangan bunga', 'Wadah penyimpanan'],
    disposalGuide:
        'Bilas dari sisa makanan/minuman, keringkan, lalu kumpulkan dalam satu wadah khusus sampah plastik.',
    environmentalImpact:
        'Plastik tidak dapat hancur secara alami, melainkan terpecah menjadi mikroplastik yang meracuni tanah, air, dan makhluk hidup.',
    decompositionTime: '100-500 Tahun',
    economicValue: 'Sedang',
    recyclingTips: [
      'Bersihkan sisa makanan agar tidak mengundang bakteri',
      'Kurangi penggunaan plastik sekali pakai',
      'Buat ecobrick dari potongan plastik kecil',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Ecobrick', url: 'https://youtube.com/shorts/g7HsT6AJkxE?si=kS8NP8YHSVeoHpCl'),
      YoutubeTutorial(label: 'Kerajinan dari Sedotan', url: 'https://youtu.be/P_rVigD7h-A'),
    ],
  ),
  'Sisa Buah dan Sayur': const WasteClassData(
    name: 'Sisa Buah dan Sayur',
    category: 'organik',
    description:
        'Sisa buah-buahan dan sayuran dapur yang kaya nutrisi dan sangat baik untuk kompos dan eco-enzyme.',
    recyclingPotential: ['Pupuk Organik Cair', 'Eco-Enzyme'],
    disposalGuide: 'Potong kecil-kecil untuk mempercepat proses pengomposan.',
    environmentalImpact: 'Menimbulkan bau busuk dan mengundang lalat pembawa penyakit.',
    decompositionTime: '2-6 Minggu',
    economicValue: 'Sedang',
    recyclingTips: [
      'Potong kecil untuk mempercepat pengomposan',
      'Buat eco-enzyme dengan rasio 3:1:10',
      'Pisahkan dari plastik pembungkus',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Pupuk Cair', url: 'https://youtu.be/wm5M7K_Snno?si=bmaZw-OTuiW2jRXy'),
      YoutubeTutorial(label: 'Eco-Enzyme', url: 'https://youtube.com/shorts/mRMvz9BgOh4?si=Hf5YtcorAWG5furz'),
    ],
  ),
  'Tumbuhan': const WasteClassData(
    name: 'Tumbuhan',
    category: 'organik',
    description:
        'Sisa potongan tanaman, daun kering, rumput, atau ranting pohon yang merupakan bahan organik alami.',
    recyclingPotential: ['Kompos', 'Mulsa (pelindung tanah)'],
    disposalGuide: 'Cacah daun atau ranting menjadi bagian kecil agar lebih cepat terurai saat dikomposkan.',
    environmentalImpact: 'Menumpuk menjadi timbulan sampah yang menyumbat saluran air jika dibuang sembarangan.',
    decompositionTime: '1-6 Bulan',
    economicValue: 'Rendah',
    recyclingTips: [
      'Cacah menjadi bagian kecil untuk mempercepat penguraian',
      'Campurkan dengan bahan hijau untuk kompos seimbang',
      'Gunakan sebagai mulsa pelindung tanah',
    ],
    youtubeTutorials: [
      YoutubeTutorial(label: 'Kompos Daun Kering', url: 'https://youtu.be/YRHcpHWtf6A?si=JBk3WjW8olL6_yxZ'),
    ],
  ),
  'battery': const WasteClassData(
    name: 'Baterai (Battery)',
    category: 'B3',
    description:
        'Baterai bekas yang mengandung bahan kimia berbahaya seperti merkuri, kadmium, dan timbal yang merusak lingkungan.',
    recyclingPotential: ['Tidak ada (Hanya pengumpulan untuk drop-point B3)'],
    disposalGuide:
        'Jangan dicampur! Masukkan ke wadah khusus/botol kaca tertutup. Bawa ke pusat pengumpulan limbah B3 terdekat atau drop-point resmi.',
    environmentalImpact: 'Mengandung merkuri dan timbal yang meracuni air tanah.',
    decompositionTime: '100 Tahun+',
    economicValue: 'Sangat Tinggi',
    recyclingTips: [
      'Jangan dicampur dengan sampah lain',
      'Simpan dalam wadah khusus tertutup',
      'Bawa ke drop-point atau bank sampah B3',
    ],
    youtubeTutorials: [],
  ),
};

