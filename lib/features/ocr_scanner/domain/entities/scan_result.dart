// lib/features/ocr_scanner/domain/entities/scan_result.dart
import 'package:equatable/equatable.dart';

class ScanResult extends Equatable {
  final String id;
  final String text;
  final DateTime timestamp;

  const ScanResult({
    required this.id,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, text, timestamp];
}
