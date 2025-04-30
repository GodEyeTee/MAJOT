// lib/features/ocr_scanner/data/models/scan_result_model.dart
import '../../domain/entities/scan_result.dart';

class ScanResultModel extends ScanResult {
  const ScanResultModel({
    required super.id,
    required super.text,
    required super.timestamp,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      id: json['id'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'timestamp': timestamp.toIso8601String()};
  }
}
