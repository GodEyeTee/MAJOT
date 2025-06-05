import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/supabase_service_client.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile(String userId);
  Future<ProfileModel> updateProfile(ProfileModel profile);
  Future<String> uploadProfilePhoto(String userId, String imagePath);
  Future<void> deleteProfilePhoto(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  // ใช้ SupabaseServiceClient แทน SupabaseClient
  SupabaseClient get _client {
    final serviceClient = SupabaseServiceClient();
    if (!serviceClient.isInitialized) {
      throw ServerException('Service client not initialized');
    }
    return serviceClient.client;
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      LoggerService.info('Getting profile for user: $userId', 'PROFILE_DS');

      // ตรวจสอบว่ามี profile อยู่แล้วหรือไม่
      final profileCheck =
          await _client
              .from('profiles')
              .select('user_id')
              .eq('user_id', userId)
              .maybeSingle();

      // ถ้าไม่มี profile ให้สร้างใหม่
      if (profileCheck == null) {
        LoggerService.info(
          'Creating new profile for user: $userId',
          'PROFILE_DS',
        );

        await _client.from('profiles').insert({
          'user_id': userId,
          'bio': null,
          'date_of_birth': null,
          'preferences': {},
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        LoggerService.info('Profile created successfully', 'PROFILE_DS');
      }

      // ดึงข้อมูลพร้อม join กับ users table
      final response =
          await _client
              .from('profiles')
              .select('''
            user_id,
            bio,
            date_of_birth,
            preferences,
            created_at,
            updated_at,
            users!inner(
              id,
              email,
              full_name,
              photo_url,
              phone_number
            )
          ''')
              .eq('user_id', userId)
              .single();

      LoggerService.info('Profile retrieved successfully', 'PROFILE_DS');
      return ProfileModel.fromJson(response);
    } catch (e) {
      LoggerService.error('Failed to get profile', 'PROFILE_DS', e);

      // Fallback: ดึงข้อมูลจาก users table
      try {
        LoggerService.info('Trying fallback to users table', 'PROFILE_DS');

        final userResponse =
            await _client.from('users').select().eq('id', userId).single();

        final profileData = {
          'user_id': userId,
          'bio': null,
          'date_of_birth': null,
          'preferences': {},
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'users': userResponse,
        };

        return ProfileModel.fromJson(profileData);
      } catch (fallbackError) {
        LoggerService.error(
          'Fallback also failed',
          'PROFILE_DS',
          fallbackError,
        );
        throw ServerException('Failed to get profile: ${e.toString()}');
      }
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      LoggerService.info(
        'Updating profile for user: ${profile.userId}',
        'PROFILE_DS',
      );

      // Update profiles table
      await _client.from('profiles').upsert({
        'user_id': profile.userId,
        'bio': profile.bio,
        'date_of_birth': profile.dateOfBirth?.toIso8601String(),
        'preferences': profile.preferences,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Update users table fields
      if (profile.displayName != null || profile.phoneNumber != null) {
        final userUpdate = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (profile.displayName != null) {
          userUpdate['full_name'] = profile.displayName;
        }
        if (profile.phoneNumber != null) {
          userUpdate['phone_number'] = profile.phoneNumber;
        }

        await _client.from('users').update(userUpdate).eq('id', profile.userId);
      }

      LoggerService.info('Profile updated successfully', 'PROFILE_DS');
      return await getProfile(profile.userId);
    } catch (e) {
      LoggerService.error('Failed to update profile', 'PROFILE_DS', e);
      throw ServerException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfilePhoto(String userId, String imagePath) async {
    try {
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profiles/$userId/$fileName';

      // Upload file
      await _client.storage.from('avatars').upload(path, imagePath as dynamic);

      final imageUrl = _client.storage.from('avatars').getPublicUrl(path);

      // Update users table
      await _client
          .from('users')
          .update({
            'photo_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      LoggerService.info('Photo uploaded successfully', 'PROFILE_DS');
      return imageUrl;
    } catch (e) {
      LoggerService.error('Failed to upload photo', 'PROFILE_DS', e);
      throw ServerException('Failed to upload photo: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      // List user's photos
      final files = await _client.storage
          .from('avatars')
          .list(path: 'profiles/$userId');

      // Delete all photos
      if (files.isNotEmpty) {
        final paths = files.map((f) => 'profiles/$userId/${f.name}').toList();
        await _client.storage.from('avatars').remove(paths);
      }

      // Clear photo_url in users table
      await _client
          .from('users')
          .update({
            'photo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      LoggerService.info('Photo deleted successfully', 'PROFILE_DS');
    } catch (e) {
      LoggerService.error('Failed to delete photo', 'PROFILE_DS', e);
      throw ServerException('Failed to delete photo: ${e.toString()}');
    }
  }
}
