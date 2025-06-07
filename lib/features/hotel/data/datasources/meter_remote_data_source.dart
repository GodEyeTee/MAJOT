import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/meter_reading_model.dart';

abstract class MeterRemoteDataSource {
  Future<List<MeterReadingModel>> getMeterReadings(String roomId);
  Future<MeterReadingModel?> getLatestReading(String roomId);
  Future<MeterReadingModel> createReading(MeterReadingModel reading);
  Future<List<MeterReadingModel>> getReadingsByMonth(DateTime month);
  Future<MeterReadingModel?> getReadingForMonth(String roomId, DateTime month);
}

class MeterRemoteDataSourceImpl implements MeterRemoteDataSource {
  final SupabaseClient supabaseClient;

  MeterRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<MeterReadingModel>> getMeterReadings(String roomId) async {
    try {
      final response = await supabaseClient
          .from('meter_readings')
          .select()
          .eq('room_id', roomId)
          .order('reading_month', ascending: false);

      return (response as List)
          .map((json) => MeterReadingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get meter readings: $e');
    }
  }

  @override
  Future<MeterReadingModel?> getLatestReading(String roomId) async {
    try {
      final response =
          await supabaseClient
              .from('meter_readings')
              .select()
              .eq('room_id', roomId)
              .order('reading_month', ascending: false)
              .limit(1)
              .maybeSingle();

      return response != null ? MeterReadingModel.fromJson(response) : null;
    } catch (e) {
      throw ServerException('Failed to get latest reading: $e');
    }
  }

  @override
  Future<MeterReadingModel> createReading(MeterReadingModel reading) async {
    try {
      final data = reading.toJson()..remove('id');
      final response =
          await supabaseClient
              .from('meter_readings')
              .insert(data)
              .select()
              .single();

      return MeterReadingModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create reading: $e');
    }
  }

  @override
  Future<List<MeterReadingModel>> getReadingsByMonth(DateTime month) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      final response = await supabaseClient
          .from('meter_readings')
          .select()
          .eq('reading_month', monthStr);

      return (response as List)
          .map((json) => MeterReadingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get readings by month: $e');
    }
  }

  @override
  Future<MeterReadingModel?> getReadingForMonth(
    String roomId,
    DateTime month,
  ) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      final response =
          await supabaseClient
              .from('meter_readings')
              .select()
              .eq('room_id', roomId)
              .eq('reading_month', monthStr)
              .maybeSingle();

      return response != null ? MeterReadingModel.fromJson(response) : null;
    } catch (e) {
      throw ServerException('Failed to get reading for month: $e');
    }
  }
}
