import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../models/history_item.dart';
import '../services/classifier_service.dart';
import '../database/database_helper.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  late AnimationController _animController;
  late Animation<double> _animValue;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animValue = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isAnalyzing = true;
      });

      final imageFile = File(pickedFile.path);
      final imageBytes = await imageFile.readAsBytes();

      // Run on-device TFLite Machine Learning
      final classificationResult = await ClassifierService.instance.classifyImage(imageFile);

      // Create base64 thumbnail
      final thumbnailBase64 = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

      // Store in SQLite database
      final historyItem = HistoryItem(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        imagePath: pickedFile.path,
        imageBase64: thumbnailBase64,
        result: classificationResult,
      );

      await DatabaseHelper.instance.insertHistory(historyItem);

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      // Navigate to Result Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(historyItem: historyItem),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pindai Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main Scanner View
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder Box
                        Container(
                          width: double.infinity,
                          height: 320,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Corner Markers
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.primary, width: 4),
                                      left: BorderSide(color: AppColors.primary, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.primary, width: 4),
                                      right: BorderSide(color: AppColors.primary, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.primary, width: 4),
                                      left: BorderSide(color: AppColors.primary, width: 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.primary, width: 4),
                                      right: BorderSide(color: AppColors.primary, width: 4),
                                    ),
                                  ),
                                ),
                              ),

                              // Center Instruction Icon
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.center_focus_strong,
                                      size: 64,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Arahkan kamera ke objek sampah',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Animated Scan Line
                              AnimatedBuilder(
                                animation: _animValue,
                                builder: (context, child) {
                                  return Positioned(
                                    top: 16 + (_animValue.value * 280),
                                    left: 20,
                                    right: 20,
                                    child: Container(
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            AppColors.primary,
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.8),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Photography Tips
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFFFBBF24), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pastikan pencahayaan cukup dan fokus pada 1 jenis sampah.',
                        style: TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons Row (Camera & Gallery)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : () => _processImage(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkSurface,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.darkBorder),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        label: const Text(
                          'Galeri',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : () => _processImage(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.camera_alt, size: 22),
                        label: const Text(
                          'Buka Kamera',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Loading Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'AI sedang menganalisis sampah...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Menggunakan TensorFlow Lite On-Device',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
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
}

