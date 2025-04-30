import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class SupabaseUserDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String id);
}

class SupabaseUserDataSourceImpl implements SupabaseUserDataSource {
  final SupabaseClient supabaseClient;

  SupabaseUserDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      // เพิ่มการตรวจสอบการเชื่อมต่อ
      if (supabaseClient.auth.currentSession == null) {
        // ถ้าไม่มี session ให้ใช้ anon key
        print('Warning: No Supabase session, using anon key');
      }

      print('Saving user to Supabase: ${user.id}, ${user.email}');

      // ระบุตาราง 'users' ชัดเจน และใช้ upsert
      await supabaseClient.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': user.displayName,
        'role': 'user', // กำหนดค่าเริ่มต้น
      }, onConflict: 'id');

      print('User saved successfully');
    } catch (e) {
      print('Supabase error details: $e');
      throw DatabaseException('Failed to save user: ${e.toString()}', e);
    }
  }

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      final response =
          await supabaseClient.from('users').select().eq('id', id).single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to get user: ${e.toString()}', e);
    }
  }
}
