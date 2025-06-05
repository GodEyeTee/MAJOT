import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service_client.dart';
import '../../../../core/services/logger_service.dart';
import '../models/user_model.dart';

abstract class SupabaseUserDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String id);
  Future<void> updateUserRole(String id, String role);
  Future<bool> validateConnection();
  Future<void> saveLoginHistory(Map<String, dynamic> loginData);
}

class SupabaseUserDataSourceImpl implements SupabaseUserDataSource {
  final SupabaseServiceClient _serviceClient;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _operationTimeout = Duration(seconds: 10);

  SupabaseUserDataSourceImpl({SupabaseServiceClient? serviceClient})
    : _serviceClient = serviceClient ?? SupabaseServiceClient();

  SupabaseClient get _client {
    if (!_serviceClient.isInitialized) {
      throw DatabaseException('Supabase Service Client not initialized');
    }
    return _serviceClient.client;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _executeWithRetry(() async {
      _validateUserModel(user);
      final userData = _sanitizeUserData(user.toJson());

      try {
        LoggerService.info('Saving user: ${user.email}', 'SUPABASE');

        await _client
            .from('users')
            .upsert(userData, onConflict: 'id')
            .timeout(_operationTimeout);

        LoggerService.info(
          'User saved successfully: ${user.email}',
          'SUPABASE',
        );
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // Duplicate key - try update
          try {
            await _client
                .from('users')
                .update({
                  'full_name': userData['full_name'],
                  'role': userData['role'],
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', user.id)
                .timeout(_operationTimeout);

            LoggerService.info(
              'User updated successfully: ${user.email}',
              'SUPABASE',
            );
            return;
          } catch (updateError) {
            throw DatabaseException(
              'Failed to save or update user: $updateError',
            );
          }
        }
        throw DatabaseException(_handlePostgrestError(e));
      } catch (e) {
        throw DatabaseException('Database operation failed: ${e.toString()}');
      }
    });
  }

  @override
  Future<UserModel?> getUser(String id) async {
    return await _executeWithRetry(() async {
      if (id.isEmpty || id.length < 10) {
        throw const DatabaseException('Invalid user ID format');
      }

      try {
        LoggerService.info('Getting user: $id', 'SUPABASE');

        final response = await _client
            .from('users')
            .select()
            .eq('id', id)
            .maybeSingle()
            .timeout(_operationTimeout);

        if (response == null) {
          LoggerService.warning('No user found with ID: $id', 'SUPABASE');
          return null;
        }

        _validateUserData(response);
        final userModel = UserModel.fromJson(response);

        LoggerService.info(
          'User retrieved successfully: ${userModel.email}',
          'SUPABASE',
        );
        return userModel;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST116') return null;
        throw DatabaseException(_handlePostgrestError(e));
      } catch (e) {
        throw DatabaseException('Failed to get user: ${e.toString()}');
      }
    });
  }

  @override
  Future<void> updateUserRole(String id, String role) async {
    await _executeWithRetry(() async {
      if (!_isValidRole(role)) {
        throw DatabaseException('Invalid role: $role');
      }

      if (id.isEmpty || id.length < 10) {
        throw const DatabaseException('Invalid user ID format');
      }

      try {
        LoggerService.info('Updating user role: $id -> $role', 'SUPABASE');

        final response = await _client
            .from('users')
            .update({
              'role': role,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single()
            .timeout(_operationTimeout);

        if (response['role'] != role) {
          throw const DatabaseException('Role update verification failed');
        }

        LoggerService.info('User role updated: $id -> $role', 'SUPABASE');
      } on PostgrestException catch (e) {
        throw DatabaseException(_handlePostgrestError(e));
      } catch (e) {
        throw DatabaseException('Role update failed: ${e.toString()}');
      }
    });
  }

  @override
  Future<bool> validateConnection() async {
    try {
      if (!_serviceClient.isInitialized) {
        return false;
      }
      return await _serviceClient.testConnection();
    } catch (e) {
      LoggerService.warning(
        'Supabase connection validation failed: $e',
        'SUPABASE',
      );
      return false;
    }
  }

  @override
  Future<void> saveLoginHistory(Map<String, dynamic> loginData) async {
    try {
      LoggerService.info('Saving login history', 'SUPABASE');

      // Use RPC function to bypass RLS
      await _client
          .rpc(
            'add_login_history',
            params: {
              'p_user_id': loginData['user_id'],
              'p_device': loginData['device'] ?? 'Unknown',
              'p_location': loginData['location'] ?? 'Unknown',
              'p_ip_address': loginData['ip_address'] ?? '0.0.0.0',
              'p_is_successful': loginData['is_successful'] ?? true,
            },
          )
          .timeout(_operationTimeout);

      LoggerService.info('Login history saved successfully', 'SUPABASE');
    } catch (e) {
      LoggerService.error('Failed to save login history', 'SUPABASE', e);
      throw DatabaseException('Failed to save login history: ${e.toString()}');
    }
  }

  void _validateUserModel(UserModel user) {
    if (user.id.isEmpty) {
      throw const DatabaseException('User ID cannot be empty');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const DatabaseException('User email cannot be empty');
    }

    if (!_isValidEmail(email)) {
      throw const DatabaseException('Invalid email format');
    }

    if (user.id.length < 10 || user.id.length > 128) {
      throw const DatabaseException('User ID length is invalid');
    }
  }

  void _validateUserData(Map<String, dynamic> data) {
    final requiredFields = ['id', 'email'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        throw DatabaseException('Missing required field: $field');
      }
    }

    if (data['id'] is! String || data['email'] is! String) {
      throw const DatabaseException('Invalid data types in user data');
    }
  }

  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    if (data['id'] != null) {
      sanitized['id'] = data['id'].toString().trim();
    }

    if (data['email'] != null) {
      sanitized['email'] = data['email'].toString().trim().toLowerCase();
    }

    if (data['full_name'] != null) {
      sanitized['full_name'] = data['full_name'].toString().trim();
    }

    if (data['role'] != null) {
      sanitized['role'] = data['role'].toString().trim().toLowerCase();
    }

    final now = DateTime.now().toIso8601String();
    sanitized['updated_at'] = now;

    if (!data.containsKey('created_at')) {
      sanitized['created_at'] = now;
    }

    return sanitized;
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Duration currentDelay = _retryDelay;

    while (attempts < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (e is DatabaseException &&
            e.message.contains('User already exists')) {
          return await operation();
        }

        if (attempts >= _maxRetries) {
          rethrow;
        }

        final jitter = Duration(
          milliseconds: (currentDelay.inMilliseconds * 0.1).round(),
        );
        final delayWithJitter = currentDelay + jitter;

        LoggerService.info(
          'Retry attempt $attempts after ${delayWithJitter.inMilliseconds}ms',
          'SUPABASE',
        );

        await Future.delayed(delayWithJitter);
        currentDelay *= 2;
      }
    }

    throw const DatabaseException(
      'Operation failed after maximum retry attempts',
    );
  }

  String _handlePostgrestError(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return 'User already exists';
      case '23503':
        return 'Invalid reference data';
      case 'PGRST301':
        return 'Access denied - insufficient permissions';
      case 'PGRST116':
        return 'User not found';
      case 'PGRST200':
        return 'Connection timeout - please try again';
      case 'PGRST202':
        return 'Service temporarily unavailable';
      case 'PGRST100':
        return 'Database connection failed';
      case 'PGRST000':
        return 'Network error - check your connection';
      default:
        return 'Database operation failed - please try again later';
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (email.length > 254 || email.length < 5) return false;
    if (email.startsWith('.') || email.endsWith('.')) return false;
    if (email.contains('..')) return false;

    return emailRegex.hasMatch(email);
  }

  bool _isValidRole(String role) {
    const validRoles = ['admin', 'editor', 'user', 'guest'];
    final normalizedRole = role.toLowerCase().trim();
    return validRoles.contains(normalizedRole) && normalizedRole.isNotEmpty;
  }

  void dispose() {
    LoggerService.info('SupabaseUserDataSource disposed', 'SUPABASE');
  }
}
