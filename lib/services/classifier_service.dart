import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/classification_result.dart';
import '../models/waste_data.dart';

class ClassifierService {
  static final ClassifierService instance = ClassifierService._init();
  ClassifierService._init();

  Interpreter? _interpreter;
  bool _isInitialized = false;
  String? _initError;

  String? get initError => _initError;
  bool get isReady => _isInitialized && _interpreter != null;

  Future<void> initialize() async {
    if (_isInitialized && _interpreter != null) return;

    _isInitialized = false;
    _initError = null;

    final errors = <String>[];

    // Strategy 1: Load directly from Asset bundle
    try {
      debugPrint('[AI] Attempting Interpreter.fromAsset...');
      _interpreter = await Interpreter.fromAsset('assets/models/waste_classifier.tflite');
      _logModelInfo('fromAsset');
      _isInitialized = true;
      _initError = null;
      return;
    } catch (e) {
      debugPrint('[AI] fromAsset failed: $e');
      errors.add('fromAsset: $e');
      _interpreter = null;
    }

    // Strategy 2: Load from local disk file
    try {
      debugPrint('[AI] Attempting Interpreter.fromFile...');
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/waste_classifier.tflite');

      const expectedSize = 34787200;
      final fileExists = await modelFile.exists();
      final currentSize = fileExists ? await modelFile.length() : 0;

      if (!fileExists || currentSize != expectedSize) {
        debugPrint('[AI] Extracting model asset to disk (${modelFile.path})...');
        final byteData = await rootBundle.load('assets/models/waste_classifier.tflite');
        final buffer = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        await modelFile.writeAsBytes(buffer, flush: true);
        debugPrint('[AI] Model asset extracted successfully (${buffer.length} bytes).');
      }

      _interpreter = Interpreter.fromFile(modelFile);
      _logModelInfo('fromFile');
      _isInitialized = true;
      _initError = null;
      return;
    } catch (e) {
      debugPrint('[AI] fromFile failed: $e');
      errors.add('fromFile: $e');
      _interpreter = null;
    }

    // Strategy 3: Load from raw byte buffer
    try {
      debugPrint('[AI] Attempting Interpreter.fromBuffer...');
      final byteData = await rootBundle.load('assets/models/waste_classifier.tflite');
      final buffer = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      _interpreter = Interpreter.fromBuffer(buffer);
      _logModelInfo('fromBuffer');
      _isInitialized = true;
      _initError = null;
      return;
    } catch (e) {
      debugPrint('[AI] fromBuffer failed: $e');
      errors.add('fromBuffer: $e');
      _interpreter = null;
    }

    _initError = errors.join(' | ');
    debugPrint('[AI] All TFLite initialization strategies failed: $_initError');
  }

  void _logModelInfo(String strategy) {
    if (_interpreter == null) return;
    try {
      final inTensors = _interpreter!.getInputTensors();
      final outTensors = _interpreter!.getOutputTensors();
      debugPrint('[AI] Model loaded successfully via $strategy.');
      debugPrint('[AI] Input: ${inTensors.first.shape} (${inTensors.first.type})');
      debugPrint('[AI] Output: ${outTensors.first.shape} (${outTensors.first.type})');
    } catch (e) {
      debugPrint('[AI] Warning reading tensor info: $e');
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
      throw Exception('Model AI belum siap: ${_initError ?? "Gagal memuat file model"}');
    }

    try {
      // 1. Decode image using package:image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Gagal membaca gambar. Format file tidak didukung.');
      }

      // 2. Resize to 224x224 (exact input required by MobileNetV2)
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // 3. Prepare normalized 4D array [1, 224, 224, 3] with values in [0.0, 1.0]
      // Matching standard TensorFlow Lite Flutter format
      final imageMatrix = List.generate(
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
      );

      final input = [imageMatrix];
      final output = [List<double>.filled(CLASS_LABELS.length, 0.0)];

      // 4. Run inference
      _interpreter!.run(input, output);

      final probabilities = output.first;

      // 5. Find predicted class with highest probability
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

      debugPrint('[AI] Predicted: $labelName ($confidence%) [index=$maxIndex]');
      for (int i = 0; i < probabilities.length && i < CLASS_LABELS.length; i++) {
        debugPrint('[AI]   [$i] ${CLASS_LABELS[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
      }

      return ClassificationResult.fromLabelAndConfidence(labelName, confidence);
    } catch (e, stackTrace) {
      debugPrint('[AI] Inference exception: $e');
      debugPrint('[AI] Stack trace: $stackTrace');
      rethrow;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

