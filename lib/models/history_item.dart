import 'classification_result.dart';

class HistoryItem {
  final String id;
  final DateTime timestamp;
  final String? imagePath;
  final String? imageBase64;
  final ClassificationResult result;
  final String? userFeedback;

  HistoryItem({
    required this.id,
    required this.timestamp,
    this.imagePath,
    this.imageBase64,
    required this.result,
    this.userFeedback,
  });

  Map<String, dynamic> toMap() {
    final resultMap = result.toMap();
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
      'image_base64': imageBase64,
      'user_feedback': userFeedback,
      ...resultMap,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as String,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      imagePath: map['image_path'] as String?,
      imageBase64: map['image_base64'] as String?,
      userFeedback: map['user_feedback'] as String?,
      result: ClassificationResult.fromMap(map),
    );
  }
}

