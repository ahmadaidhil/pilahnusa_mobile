import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/classification_result.dart';
import '../models/waste_data.dart';

class ClassifierService {
  static final ClassifierService instance = ClassifierService._init();
  ClassifierService._init();

  Interpreter? _interpreter;
  bool _isInitialized = false;
  String? _initError;

  Future<void> initialize() async {
    if (_isInitialized && _interpreter != null) return;

    // Reset state on re-init attempt
    _isInitialized = false;
    _initError = null;

    // Try multiple asset path variants with Interpreter.fromAsset
    final assetPaths = [
      'models/waste_classifier.tflite',
      'assets/models/waste_classifier.tflite',
    ];

    for (final assetPath in assetPaths) {
      try {
        final options = InterpreterOptions();
        options.threads = 2;

        _interpreter = await Interpreter.fromAsset(
          assetPath,
          options: options,
        );

        // Verify interpreter is functional
        final inputTensors = _interpreter!.getInputTensors();
        final outputTensors = _interpreter!.getOutputTensors();
        debugPrint('[AI] Model loaded from "$assetPath"');
        debugPrint('[AI] Input tensor: ${inputTensors[0].shape} type=${inputTensors[0].type}');
        debugPrint('[AI] Output tensor: ${outputTensors[0].shape} type=${outputTensors[0].type}');

        _isInitialized = true;
        _initError = null;
        debugPrint('[AI] PilahNusa TFLite model initialized successfully.');
        return;
      } catch (e) {
        debugPrint('[AI] Failed to load from "$assetPath": $e');
        _initError = e.toString();
        _interpreter = null;
      }
    }

    // Direct buffer fallback: load bytes explicitly via rootBundle
    // with exact offset and length to avoid Flutter asset slice offset issues
    for (final assetPath in ['assets/models/waste_classifier.tflite', 'models/waste_classifier.tflite']) {
      try {
        debugPrint('[AI] Attempting direct rootBundle.load for "$assetPath"...');
        final rawAsset = await rootBundle.load(assetPath);
        final bytes = rawAsset.buffer.asUint8List(
          rawAsset.offsetInBytes,
          rawAsset.lengthInBytes,
        );
        final options = InterpreterOptions()..threads = 2;
        _interpreter = Interpreter.fromBuffer(bytes, options: options);

        final inputTensors = _interpreter!.getInputTensors();
        final outputTensors = _interpreter!.getOutputTensors();
        debugPrint('[AI] Model loaded via fromBuffer("$assetPath")');
        debugPrint('[AI] Input tensor: ${inputTensors[0].shape} type=${inputTensors[0].type}');
        debugPrint('[AI] Output tensor: ${outputTensors[0].shape} type=${outputTensors[0].type}');

        _isInitialized = true;
        _initError = null;
        debugPrint('[AI] PilahNusa TFLite model initialized successfully via fromBuffer.');
        return;
      } catch (e) {
        debugPrint('[AI] fromBuffer failed for "$assetPath": $e');
        _initError = e.toString();
        _interpreter = null;
      }
    }

    debugPrint('[AI] CRITICAL: Could not load model from any asset path. Last error: $_initError');
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
      debugPrint('[AI] Model not available. Error: $_initError');
      return _generateFallbackClassification(
        errorMsg: 'Model AI belum tersedia: ${_initError ?? "Unknown error"}',
      );
    }

    try {
      // 1. Decode image using package:image
      debugPrint('[AI] Decoding image (${imageBytes.length} bytes)...');
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Gagal memproses gambar. Format tidak didukung.');
      }
      debugPrint('[AI] Image decoded: ${image.width}x${image.height}');

      // 2. Resize to 224x224 (exact input required by MobileNetV2)
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // 3. Build Float32 input tensor [1, 224, 224, 3], normalized to [0.0, 1.0]
      // Use flat Float32List for better performance and compatibility
      final inputBuffer = Float32List(1 * 224 * 224 * 3);
      int offset = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputBuffer[offset++] = pixel.r / 255.0;
          inputBuffer[offset++] = pixel.g / 255.0;
          inputBuffer[offset++] = pixel.b / 255.0;
        }
      }

      // 4. Output tensor: [1, 10]
      final outputBuffer = Float32List(10);

      // 5. Run inference using raw ByteBuffer (guarantees fast zero-copy without shape mismatch)
      debugPrint('[AI] Running inference...');
      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

      // 6. Find predicted class with highest probability
      debugPrint('[AI] Raw output: ${outputBuffer.toList()}');
      debugPrint('[AI] Output sum: ${outputBuffer.reduce((a, b) => a + b)}');

      int maxIndex = 0;
      double maxProbability = outputBuffer[0];

      for (int i = 1; i < outputBuffer.length; i++) {
        if (outputBuffer[i] > maxProbability) {
          maxProbability = outputBuffer[i];
          maxIndex = i;
        }
      }

      final labelName = (maxIndex >= 0 && maxIndex < CLASS_LABELS.length)
          ? CLASS_LABELS[maxIndex]
          : 'Plastik';

      final confidence = double.parse((maxProbability * 100).toStringAsFixed(2));

      debugPrint('[AI] Predicted: $labelName ($confidence%) [index=$maxIndex]');
      debugPrint('[AI] All probabilities:');
      for (int i = 0; i < outputBuffer.length && i < CLASS_LABELS.length; i++) {
        debugPrint('[AI]   [$i] ${CLASS_LABELS[i]}: ${(outputBuffer[i] * 100).toStringAsFixed(2)}%');
      }

      return ClassificationResult.fromLabelAndConfidence(labelName, confidence);
    } catch (e, stackTrace) {
      debugPrint('[AI] Inference error: $e');
      debugPrint('[AI] Stack trace: $stackTrace');
      return _generateFallbackClassification(errorMsg: e.toString());
    }
  }

  ClassificationResult _generateFallbackClassification({String? errorMsg}) {
    debugPrint('[AI] Using fallback classification. Reason: ${errorMsg ?? "unknown"}');
    // Return "Plastik" with low confidence to signal the result is unreliable
    return ClassificationResult.fromLabelAndConfidence('Plastik', 25.00);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

