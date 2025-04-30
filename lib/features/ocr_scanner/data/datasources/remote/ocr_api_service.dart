// lib/features/ocr_scanner/data/datasources/remote/ocr_api_service.dart
import 'package:dio/dio.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../models/scan_result_model.dart';

class OcrApiService {
  final Dio dio;

  OcrApiService({required this.dio});

  Future<ScanResultModel> scanImage(String base64Image) async {
    try {
      // Placeholder implementation
      return ScanResultModel(
        id: '1',
        text: 'Sample text',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Failed to scan image: ${e.toString()}');
    }
  }
}
