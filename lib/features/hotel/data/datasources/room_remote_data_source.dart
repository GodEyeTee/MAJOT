import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service_client.dart';
import '../models/room_model.dart';

abstract class RoomRemoteDataSource {
  Future<List<RoomModel>> getRooms();
  Future<RoomModel> getRoom(String id);
  Future<RoomModel> createRoom(RoomModel room);
  Future<RoomModel> updateRoom(RoomModel room);
  Future<void> deleteRoom(String id);
  Future<List<RoomModel>> getRoomsByStatus(String status);
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final SupabaseClient supabaseClient;

  RoomRemoteDataSourceImpl({required this.supabaseClient});

  // ใช้ service client สำหรับ bypass RLS
  SupabaseClient get _serviceClient => SupabaseServiceClient().client;

  @override
  Future<List<RoomModel>> getRooms() async {
    try {
      final response = await _serviceClient // เปลี่ยนจาก supabaseClient
          .from('rooms')
          .select()
          .order('room_number');

      return (response as List)
          .map((json) => RoomModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get rooms: $e');
    }
  }

  @override
  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      final data = room.toJson()..remove('id');
      final response =
          await _serviceClient // เปลี่ยนจาก supabaseClient
              .from('rooms')
              .insert(data)
              .select()
              .single();

      return RoomModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create room: $e');
    }
  }

  // เปลี่ยน method อื่นๆ ให้ใช้ _serviceClient เช่นกัน
  @override
  Future<RoomModel> getRoom(String id) async {
    try {
      final response =
          await _serviceClient.from('rooms').select().eq('id', id).single();

      return RoomModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to get room: $e');
    }
  }

  @override
  Future<RoomModel> updateRoom(RoomModel room) async {
    try {
      final data =
          room.toJson()
            ..remove('created_at')
            ..remove('created_by');

      final response =
          await _serviceClient
              .from('rooms')
              .update(data)
              .eq('id', room.id)
              .select()
              .single();

      return RoomModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update room: $e');
    }
  }

  @override
  Future<void> deleteRoom(String id) async {
    try {
      await _serviceClient.from('rooms').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete room: $e');
    }
  }

  @override
  Future<List<RoomModel>> getRoomsByStatus(String status) async {
    try {
      final response = await _serviceClient
          .from('rooms')
          .select()
          .eq('status', status)
          .order('room_number');

      return (response as List)
          .map((json) => RoomModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get rooms by status: $e');
    }
  }
}
