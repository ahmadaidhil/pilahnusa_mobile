import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../models/history_item.dart';
import '../services/classifier_service.dart';
import '../database/database_helper.dart';
import '../widgets/stat_card.dart';
import 'result_screen.dart';
import 'team_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Map<String, int> _stats = {
    'total': 0,
    'organik': 0,
    'anorganik': 0,
    'b3': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<void> _pickAndClassify(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
      });

      final imageFile = File(pickedFile.path);
      final imageBytes = await imageFile.readAsBytes();

      // Run on-device TFLite Machine Learning
      final classificationResult = await ClassifierService.instance.classifyImage(imageFile);

      final thumbnailBase64 = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

      final historyItem = HistoryItem(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        imagePath: pickedFile.path,
        imageBase64: thumbnailBase64,
        result: classificationResult,
      );

      await DatabaseHelper.instance.insertHistory(historyItem);
      await _loadStats();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(historyItem: historyItem),
        ),
      ).then((_) => _loadStats());
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.recycling, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'PilahNusa AI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Tim Pengembang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadStats,
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: Colors.yellow, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'AI Waste Classification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Scan Sampahmu,\nPelajari Pengelolaannya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Identifikasi sampah secara otomatis dengan Machine Learning langsung di ponsel Anda.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: () => _pickAndClassify(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryDarker,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text(
                                  'Scan Sekarang',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: () => _pickAndClassify(ImageSource.gallery),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.photo_library, size: 16),
                                label: const Text(
                                  'Galeri',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statistik Pemindaian Anda',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onTabChange(2), // go to History tab
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4 Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Scan',
                          count: _stats['total'] ?? 0,
                          color: AppColors.primaryDark,
                          backgroundColor: AppColors.primaryBg,
                          icon: Icons.history,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Organik',
                          count: _stats['organik'] ?? 0,
                          color: AppColors.organik,
                          backgroundColor: AppColors.organikBg,
                          icon: Icons.eco,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Anorganik',
                          count: _stats['anorganik'] ?? 0,
                          color: AppColors.anorganik,
                          backgroundColor: AppColors.anorganikBg,
                          icon: Icons.delete_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'B3',
                          count: _stats['b3'] ?? 0,
                          color: AppColors.b3,
                          backgroundColor: AppColors.b3Bg,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 3 Easy Steps Section
                  const Text(
                    '3 Langkah Mudah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    number: '1',
                    title: 'Foto Sampah',
                    description: 'Ambil foto sampah atau pilih dari galeri perangkat Anda.',
                    icon: Icons.camera_alt_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    number: '2',
                    title: 'AI Menganalisis',
                    description: 'Model Machine Learning mengklasifikasikan jenis sampah secara offline.',
                    icon: Icons.psychology_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    number: '3',
                    title: 'Dapatkan Panduan',
                    description: 'Pelajari kategori, waktu terurai, dan tips daur ulang yang bermanfaat.',
                    icon: Icons.lightbulb_outline,
                  ),

                  const SizedBox(height: 28),

                  // Kategori Sampah Overview
                  const Text(
                    'Kategori Sampah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryPreviewCard(
                    title: 'Organik',
                    subtitle: 'Sisa makanan, buah, daun & ranting',
                    color: AppColors.organik,
                    bgColor: AppColors.organikBg,
                    icon: Icons.compost,
                    onTap: () => widget.onTabChange(3), // Guide tab
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryPreviewCard(
                    title: 'Anorganik',
                    subtitle: 'Plastik, kertas, botol kaca & kaleng metal',
                    color: AppColors.anorganik,
                    bgColor: AppColors.anorganikBg,
                    icon: Icons.recycling,
                    onTap: () => widget.onTabChange(3),
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryPreviewCard(
                    title: 'B3 (Bahan Berbahaya)',
                    subtitle: 'Baterai bekas, lampu, limbah kimia & aerosol',
                    color: AppColors.b3,
                    bgColor: AppColors.b3Bg,
                    icon: Icons.warning_rounded,
                    onTap: () => widget.onTabChange(3),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    SizedBox(height: 20),
                    Text(
                      'AI sedang menganalisis foto...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }

  Widget _buildCategoryPreviewCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

