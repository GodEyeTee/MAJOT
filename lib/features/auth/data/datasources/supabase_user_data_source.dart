// lib/features/auth/data/datasources/supabase_user_data_source.dart - เวอร์ชัน Debug
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class SupabaseUserDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String id);
  Future<void> updateUserRole(String id, String role);
}

class SupabaseUserDataSourceImpl implements SupabaseUserDataSource {
  final SupabaseClient supabaseClient;

  SupabaseUserDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      print('🔄 [SUPABASE] Starting to save user...');
      print('🔄 [SUPABASE] User ID: ${user.id}');
      print('🔄 [SUPABASE] User Email: ${user.email}');
      print('🔄 [SUPABASE] User Name: ${user.displayName}');
      print('🔄 [SUPABASE] User Role: ${user.role}');

      // ทดสอบการเชื่อมต่อก่อน
      print('🔍 [SUPABASE] Testing connection...');
      final testQuery = await supabaseClient
          .from('users')
          .select('count')
          .count(CountOption.exact);
      print('✅ [SUPABASE] Connection OK. Current user count: $testQuery');

      // เตรียมข้อมูลสำหรับ insert
      final userData = {
        'id': user.id,
        'email': user.email,
        'full_name': user.displayName,
        'role': user.role.toString().split('.').last,
      };

      print('🔄 [SUPABASE] Data to insert: $userData');

      // ลองใช้ insert ก่อน (ไม่ใช้ upsert)
      try {
        print('🔄 [SUPABASE] Attempting INSERT...');
        final insertResponse =
            await supabaseClient.from('users').insert(userData).select();

        print('✅ [SUPABASE] INSERT successful: $insertResponse');
      } catch (insertError) {
        print('⚠️ [SUPABASE] INSERT failed, trying UPSERT...');
        print('⚠️ [SUPABASE] INSERT error: $insertError');

        // ถ้า insert ไม่สำเร็จ ลอง upsert
        final upsertResponse =
            await supabaseClient
                .from('users')
                .upsert(userData, onConflict: 'id')
                .select();

        print('✅ [SUPABASE] UPSERT successful: $upsertResponse');
      }

      // ตรวจสอบว่าข้อมูลถูกบันทึกจริงหรือไม่
      print('🔍 [SUPABASE] Verifying saved data...');
      final verifyResponse =
          await supabaseClient
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (verifyResponse != null) {
        print('✅ [SUPABASE] Verification successful: $verifyResponse');
      } else {
        print('❌ [SUPABASE] Verification failed: User not found after insert');
        throw DatabaseException('User was not saved properly');
      }
    } catch (e) {
      print('❌ [SUPABASE] Save user error: $e');
      print('❌ [SUPABASE] Error type: ${e.runtimeType}');

      // พิมพ์รายละเอียด error เพิ่มเติม
      if (e is PostgrestException) {
        print('❌ [SUPABASE] Postgrest Error Details:');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }

      // ทดสอบ RLS policies
      print('🔍 [SUPABASE] Testing RLS policies...');
      try {
        final policyTest = await supabaseClient
            .from('users')
            .select('id')
            .limit(1);
        print('✅ [SUPABASE] RLS read test passed: $policyTest');
      } catch (rlsError) {
        print('❌ [SUPABASE] RLS read test failed: $rlsError');
      }

      throw DatabaseException('Failed to save user: ${e.toString()}', e);
    }
  }

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      print('🔍 [SUPABASE] Getting user: $id');

      final response =
          await supabaseClient
              .from('users')
              .select()
              .eq('id', id)
              .maybeSingle();

      if (response == null) {
        print('⚠️ [SUPABASE] User not found: $id');

        // ลองหาด้วย email
        print('🔍 [SUPABASE] Searching by email pattern...');
        final emailSearch = await supabaseClient
            .from('users')
            .select()
            .limit(5);
        print('📊 [SUPABASE] Available users: $emailSearch');

        return null;
      }

      print('✅ [SUPABASE] User found: $response');
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ [SUPABASE] Get user error: $e');

      if (e is PostgrestException) {
        print('❌ [SUPABASE] Postgrest Error Details:');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');

        // ถ้าไม่เจอข้อมูล ให้ return null แทนที่จะ throw error
        if (e.code == 'PGRST116') {
          print('⚠️ [SUPABASE] No rows returned (user not found)');
          return null;
        }
      }

      throw DatabaseException('Failed to get user: ${e.toString()}', e);
    }
  }

  @override
  Future<void> updateUserRole(String id, String role) async {
    try {
      print('🔄 [SUPABASE] Updating user role: $id -> $role');

      await supabaseClient.from('users').update({'role': role}).eq('id', id);

      print('✅ [SUPABASE] User role updated successfully');
    } catch (e) {
      print('❌ [SUPABASE] Failed to update user role: $e');
      throw DatabaseException('Failed to update user role: ${e.toString()}', e);
    }
  }

  // 🔧 Helper method สำหรับทดสอบการเชื่อมต่อ
  Future<bool> testConnection() async {
    try {
      print('🔌 [SUPABASE] Testing connection...');

      final response = await supabaseClient
          .from('users')
          .select('count')
          .count(CountOption.exact);

      print('✅ [SUPABASE] Connection test successful. User count: $response');
      return true;
    } catch (e) {
      print('❌ [SUPABASE] Connection test failed: $e');

      if (e is PostgrestException) {
        print('❌ [SUPABASE] Connection error details:');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
      }

      return false;
    }
  }

  // 🔍 Helper method สำหรับดูข้อมูลทั้งหมด (สำหรับ debug)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('📊 [SUPABASE] Getting all users...');

      final response = await supabaseClient.from('users').select();

      print('📊 [SUPABASE] All users in database: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [SUPABASE] Failed to get all users: $e');
      return [];
    }
  }

  // 🧪 Helper method สำหรับทดสอบ insert ด้วยข้อมูลจำลอง
  Future<void> testInsert() async {
    try {
      final testUser = {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'email': 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        'full_name': 'Test User',
        'role': 'user',
      };

      print('🧪 [SUPABASE] Testing insert with dummy data: $testUser');

      final response =
          await supabaseClient.from('users').insert(testUser).select();

      print('✅ [SUPABASE] Test insert successful: $response');
    } catch (e) {
      print('❌ [SUPABASE] Test insert failed: $e');
      rethrow;
    }
  }
}
