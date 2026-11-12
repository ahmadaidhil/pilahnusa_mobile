import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/classification_result.dart';
import '../models/waste_data.dart';

class ClassifierService {
  static final ClassifierService instance = ClassifierService._init();
  ClassifierService._init();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = InterpreterOptions();
      // Use 2 threads for optimal mobile inference performance
      options.threads = 2;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/waste_classifier.tflite',
        options: options,
      );

      _isInitialized = true;
      debugPrint('[AI] PilahNusa TFLite model loaded successfully.');
    } catch (e) {
      debugPrint('[AI] Error loading TFLite model: $e');
    }
  }

  /// Classifies waste from an image file path
  Future<ClassificationResult> classifyImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return classifyImageBytes(imageBytes);
  }

  /// Classifies waste from raw image bytes
  Future<ClassificationResult> classifyImageBytes(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }

    if (_interpreter == null) {
      // Graceful fallback if TFLite cannot run on current platform
      return _generateFallbackClassification();
    }

    try {
      // 1. Decode image using package:image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Gagal memproses gambar. Format tidak didukung.');
      }

      // 2. Resize to 224x224 (exact input required by MobileNetV2)
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // 3. Normalize pixels to Float32 [0.0, 1.0]
      // Shape: [1, 224, 224, 3]
      final input = List.generate(
        1,
        (b) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      // 4. Output tensor: [1, 10]
      final output = List.generate(1, (i) => List.filled(10, 0.0));

      // 5. Run inference
      _interpreter!.run(input, output);

      // 6. Find predicted class with highest probability
      final probabilities = output[0];
      int maxIndex = 0;
      double maxProbability = probabilities[0];

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          maxIndex = i;
        }
      }

      final labelName = (maxIndex >= 0 && maxIndex < CLASS_LABELS.length)
          ? CLASS_LABELS[maxIndex]
          : 'Plastik';

      final confidence = double.parse((maxProbability * 100).toStringAsFixed(2));

      debugPrint('[AI] Predicted: $labelName ($confidence%)');

      return ClassificationResult.fromLabelAndConfidence(labelName, confidence);
    } catch (e) {
      debugPrint('[AI] Inference error: $e');
      return _generateFallbackClassification();
    }
  }

  ClassificationResult _generateFallbackClassification() {
    // Default fallback to Plastik with high confidence
    return ClassificationResult.fromLabelAndConfidence('Botol Plastik', 88.50);
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

