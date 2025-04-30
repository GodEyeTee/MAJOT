// lib/features/hotel_booking/data/datasources/remote/hotel_api_service.dart
import 'package:dio/dio.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../models/hotel_model.dart';

class HotelApiService {
  final Dio dio;

  HotelApiService({required this.dio});

  Future<List<HotelModel>> getHotels() async {
    try {
      // Placeholder implementation
      return [];
    } catch (e) {
      throw ServerException('Failed to get hotels: ${e.toString()}');
    }
  }
}
