// lib/features/hotel_booking/data/datasources/local/hotel_cache_service.dart
import '../../../../../core/errors/exceptions.dart';
import '../../models/hotel_model.dart';

class HotelCacheService {
  Future<void> cacheHotels(List<HotelModel> hotels) async {
    // Placeholder implementation
  }

  Future<List<HotelModel>?> getCachedHotels() async {
    try {
      // Placeholder implementation
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached hotels: ${e.toString()}');
    }
  }
}
