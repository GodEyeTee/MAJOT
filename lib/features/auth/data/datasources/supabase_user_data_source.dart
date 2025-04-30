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
      await supabaseClient.from('users').upsert(user.toJson());
    } catch (e) {
      throw DatabaseException('Failed to save user: ${e.toString()}', e);
    }
  }

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      final response =
          await supabaseClient.from('users').select().eq('id', id).single();

      if (response == null) {
        return null;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to get user: ${e.toString()}', e);
    }
  }
}
