import 'dart:convert';
import 'waste_data.dart';

class ClassificationResult {
  final String name;
  final String category;
  final double confidence;
  final String description;
  final List<String> recyclingTips;
  final List<String> recyclingPotential;
  final String disposalGuide;
  final String? environmentalImpact;
  final String decompositionTime;
  final String? economicValue;
  final List<YoutubeTutorial> youtubeTutorials;

  ClassificationResult({
    required this.name,
    required this.category,
    required this.confidence,
    required this.description,
    required this.recyclingTips,
    required this.recyclingPotential,
    required this.disposalGuide,
    this.environmentalImpact,
    required this.decompositionTime,
    this.economicValue,
    required this.youtubeTutorials,
  });

  factory ClassificationResult.fromLabelAndConfidence(String label, double confidence) {
    final richData = WASTE_DATA_MAP[label] ??
        WasteClassData(
          name: label,
          category: 'anorganik',
          description: 'Objek sampah berhasil terdeteksi.',
          recyclingPotential: [],
          disposalGuide: 'Buang pada tempat sampah yang sesuai.',
          environmentalImpact: 'Dapat mencemari lingkungan jika dibiarkan.',
          decompositionTime: '-',
          economicValue: 'Sedang',
          recyclingTips: ['Pisahkan dari sampah organik'],
          youtubeTutorials: [],
        );

    return ClassificationResult(
      name: richData.name,
      category: richData.category,
      confidence: confidence,
      description: richData.description,
      recyclingTips: richData.recyclingTips,
      recyclingPotential: richData.recyclingPotential,
      disposalGuide: richData.disposalGuide,
      environmentalImpact: richData.environmentalImpact,
      decompositionTime: richData.decompositionTime,
      economicValue: richData.economicValue,
      youtubeTutorials: richData.youtubeTutorials,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'confidence': confidence,
      'description': description,
      'disposal_guide': disposalGuide,
      'environmental_impact': environmentalImpact,
      'decomposition_time': decompositionTime,
      'economic_value': economicValue,
      'recycling_tips': jsonEncode(recyclingTips),
      'recycling_potential': jsonEncode(recyclingPotential),
      'youtube_tutorials': jsonEncode(youtubeTutorials.map((e) => e.toMap()).toList()),
    };
  }

  factory ClassificationResult.fromMap(Map<String, dynamic> map) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      try {
        final decoded = jsonDecode(value.toString());
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [];
    }

    List<YoutubeTutorial> parseTutorials(dynamic value) {
      if (value == null) return [];
      try {
        final decoded = value is List ? value : jsonDecode(value.toString());
        if (decoded is List) {
          return decoded
              .map((item) => YoutubeTutorial.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      } catch (_) {}
      return [];
    }

    return ClassificationResult(
      name: map['name'] as String? ?? 'Unknown',
      category: map['category'] as String? ?? 'unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      disposalGuide: map['disposal_guide'] as String? ?? '-',
      environmentalImpact: map['environmental_impact'] as String?,
      decompositionTime: map['decomposition_time'] as String? ?? '-',
      economicValue: map['economic_value'] as String?,
      recyclingTips: parseStringList(map['recycling_tips']),
      recyclingPotential: parseStringList(map['recycling_potential']),
      youtubeTutorials: parseTutorials(map['youtube_tutorials']),
    );
  }
}

