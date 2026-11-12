import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/category_badge.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Panduan Pemilahan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco_rounded, size: 48, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilah Sampah, Selamatkan Bumi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Memilah sampah dari sumbernya adalah langkah awal menciptakan lingkungan yang berkelanjutan.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              '3 Kategori Utama Sampah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Card 1: Organik
            _buildCategoryGuideCard(
              title: 'Sampah Organik',
              category: 'Organik',
              color: AppColors.organik,
              bgColor: AppColors.organikBg,
              description:
                  'Sampah yang berasal dari sisa makhluk hidup (tumbuhan & hewan) yang dapat terurai secara alami oleh mikroorganisme tanah.',
              examples: ['Sisa sayur & buah', 'Nasi & sisa makanan', 'Daun kering & ranting', 'Kulit telur'],
              management: [
                'Olah menjadi pupuk kompos untuk tanaman.',
                'Buat eco-enzyme dari sisa kulit buah segar.',
                'Tiriskan kuah/air berlebih sebelum dimasukkan ke wadah kompos.',
              ],
            ),

            const SizedBox(height: 16),

            // Card 2: Anorganik
            _buildCategoryGuideCard(
              title: 'Sampah Anorganik',
              category: 'Anorganik',
              color: AppColors.anorganik,
              bgColor: AppColors.anorganikBg,
              description:
                  'Sampah yang dihasilkan dari proses sintetis atau industri. Membutuhkan waktu puluhan hingga ratusan tahun untuk terurai di alam.',
              examples: ['Botol & gelas plastik', 'Kardus, kertas, & karton', 'Kaleng metal & aluminium', 'Kaca & botol sirup'],
              management: [
                'Bilas bersih dari sisa cairan atau minyak.',
                'Remas atau pipihkan kardus & botol plastik untuk hemat ruang.',
                'Kumpulkan dan salurkan ke Bank Sampah untuk didaur ulang bernilai ekonomi.',
              ],
            ),

            const SizedBox(height: 16),

            // Card 3: B3
            _buildCategoryGuideCard(
              title: 'Sampah B3 (Berbahaya & Beracun)',
              category: 'B3',
              color: AppColors.b3,
              bgColor: AppColors.b3Bg,
              description:
                  'Limbah yang mengandung senyawa kimia beracun, mudah meledak, atau mudah terbakar yang dapat merusak ekosistem dan kesehatan manusia.',
              examples: ['Baterai bekas & aki', 'Lampu neon / bohlam', 'Obat kadaluarsa', 'Kaleng semprot aerosol', 'Termometer air raksa'],
              management: [
                'JANGAN pernah dicampur dengan sampah rumah tangga lainnya!',
                'Simpan di wadah kaca tertutup dan tidak mudah bocor.',
                'Antar langsung ke drop-point limbah B3 resmi atau Dinas Lingkungan Hidup.',
              ],
            ),

            const SizedBox(height: 24),

            // 3R Principles Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.autorenew_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Prinsip 3R (Pengelolaan Sampah)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _build3RItem(
                    title: '1. Reduce (Mengurangi)',
                    desc: 'Kurangi pemakaian barang sekali pakai. Bawa kantong belanja kain dan botol minum (tumbler) sendiri.',
                    icon: Icons.remove_circle_outline,
                    color: Colors.orange,
                  ),
                  const Divider(height: 24),
                  _build3RItem(
                    title: '2. Reuse (Menggunakan Kembali)',
                    desc: 'Gunakan kembali wadah yang masih layak pakai seperti toples kaca, kaleng, atau kardus kemasan.',
                    icon: Icons.loop_rounded,
                    color: AppColors.primary,
                  ),
                  const Divider(height: 24),
                  _build3RItem(
                    title: '3. Recycle (Mendaur Ulang)',
                    desc: 'Daur ulang material sampah menjadi produk baru bernilai guna atau kreasikan menjadi kerajinan tangan kreatif.',
                    icon: Icons.recycling_rounded,
                    color: AppColors.anorganik,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGuideCard({
    required String title,
    required String category,
    required Color color,
    required Color bgColor,
    required String description,
    required List<String> examples,
    required List<String> management,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              CategoryBadge(category: category),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Contoh Sampah:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: examples.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Langkah Pengelolaan:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ...management.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded, color: color, size: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3RItem({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

