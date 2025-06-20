import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service_client.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel?> getUserByEmail(String email);
  Future<UserModel> createGuestUser({
    required String email,
    required String displayName,
    String? phone,
  });
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient supabaseClient;

  UserRemoteDataSourceImpl({required this.supabaseClient});

  SupabaseClient get _serviceClient => SupabaseServiceClient().client;

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await supabaseClient
          .from('users')
          .select()
          .eq('role', 'guest') // เฉพาะ guest users
          .order('created_at');

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get users: $e');
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response =
          await supabaseClient
              .from('users')
              .select()
              .eq('email', email)
              .maybeSingle();

      return response != null ? UserModel.fromJson(response) : null;
    } catch (e) {
      throw ServerException('Failed to get user by email: $e');
    }
  }

  @override
  Future<UserModel> createGuestUser({
    required String email,
    required String displayName,
    String? phone,
  }) async {
    try {
      // Generate guest UID
      final guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // สร้างข้อมูลพื้นฐานเท่านั้น
      final userData = {
        'id': guestUid,
        'email': email,
        'role': 'guest',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _serviceClient.from('users').insert(userData).select().single();

      // เพิ่มข้อมูลเพิ่มเติมใน response สำหรับใช้ใน app
      response['display_name'] = displayName;
      response['phone'] = phone;
      response['is_guest'] = true;

      return UserModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create guest user: $e');
    }
  }
}
