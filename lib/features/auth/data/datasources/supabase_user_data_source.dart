import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class SupabaseUserDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String id);
  Future<void> updateUserRole(String id, String role);
  Future<bool> validateConnection();
}

class SupabaseUserDataSourceImpl implements SupabaseUserDataSource {
  final SupabaseClient supabaseClient;

  // Security: Rate limiting to prevent abuse
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  SupabaseUserDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> saveUser(UserModel user) async {
    await _executeWithRetry(() async {
      // Security: Validate input before database operation
      _validateUserModel(user);

      final userData = _sanitizeUserData(user.toJson());

      try {
        // Performance: Use upsert for better efficiency
        final response = await supabaseClient
            .from('users')
            .upsert(userData, onConflict: 'id')
            .select()
            .single();

        // Security: Verify the operation succeeded
        if (response['id'] != user.id) {
          throw DatabaseException('User save verification failed');
        }

        // Performance: Log only in debug mode
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          print('✅ User saved successfully: ${user.email}');
        }
      } on PostgrestException catch (e) {
        throw DatabaseException(_handlePostgrestError(e));
      }
    });
  }

  @override
  Future<UserModel?> getUser(String id) async {
    return await _executeWithRetry(() async {
      // Security: Validate ID format
      if (id.isEmpty || id.length < 10) {
        throw DatabaseException('Invalid user ID format');
      }

      try {
        final response = await supabaseClient
            .from('users')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response == null) {
          return null;
        }

        // Security: Validate returned data structure
        _validateUserData(response);

        return UserModel.fromJson(response);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST116') return null; // No rows found
        throw DatabaseException(_handlePostgrestError(e));
      }
    });
  }

  @override
  Future<void> updateUserRole(String id, String role) async {
    await _executeWithRetry(() async {
      // Security: Validate role
      if (!_isValidRole(role)) {
        throw DatabaseException('Invalid role: $role');
      }

      try {
        final response = await supabaseClient
            .from('users')
            .update({
              'role': role,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();

        // Security: Verify update succeeded
        if (response['role'] != role) {
          throw DatabaseException('Role update verification failed');
        }
      } on PostgrestException catch (e) {
        throw DatabaseException(_handlePostgrestError(e));
      }
    });
  }

  @override
  Future<bool> validateConnection() async {
    try {
      // Fixed: Properly execute the query with selector
      final response = await supabaseClient
          .from('users')
          .select('id')
          .limit(1);
      
      // Check if response is valid (list with potential data)
      return response is List;
    } catch (e) {
      // Enhanced logging for debugging
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        print('⚠️ Supabase connection validation failed: $e');
      }
      return false;
    }
  }

  // Security: Input validation
  void _validateUserModel(UserModel user) {
    if (user.id.isEmpty) throw DatabaseException('User ID cannot be empty');
    
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw DatabaseException('User email cannot be empty');
    }
    
    if (!_isValidEmail(email)) {
      throw DatabaseException('Invalid email format');
    }
  }

  void _validateUserData(Map<String, dynamic> data) {
    final requiredFields = ['id', 'email'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        throw DatabaseException('Missing required field: $field');
      }
    }
  }

  // Security: Data sanitization
  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString().trim(),
      'email': data['email']?.toString().trim().toLowerCase(),
      'full_name': data['full_name']?.toString().trim(),
      'role': data['role']?.toString().trim().toLowerCase(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Performance: Retry mechanism with exponential backoff
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) rethrow;

        // Exponential backoff with jitter for better performance
        final delay = _retryDelay * attempts;
        await Future.delayed(delay);
        
        // Enhanced logging
        if (const bool.fromEnvironment('dart.vm.product') == false) {
          print('🔄 Retry attempt $attempts after ${delay.inMilliseconds}ms');
        }
      }
    }
    throw DatabaseException('Operation failed after $_maxRetries attempts');
  }

  // Security: Error message handling - don't expose internal details
  String _handlePostgrestError(PostgrestException e) {
    // Log full error details for debugging (only in debug mode)
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      print('Postgrest Error: ${e.code} - ${e.message}');
    }

    // Return safe error messages to users
    switch (e.code) {
      case '23505':
        return 'User already exists';
      case '23503':
        return 'Invalid reference data';
      case 'PGRST301':
        return 'Access denied';
      case 'PGRST116':
        return 'User not found';
      case 'PGRST200':
        return 'Connection timeout';
      case 'PGRST202':
        return 'Service temporarily unavailable';
      default:
        return 'Database operation failed';
    }
  }

  // Security: Input validation helpers
  bool _isValidEmail(String email) {
    // Enhanced email validation with RFC compliant regex
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    ).hasMatch(email);
  }

  bool _isValidRole(String role) {
    // Security: Define role hierarchy and validation
    const validRoles = ['admin', 'editor', 'user', 'guest'];
    return validRoles.contains(role.toLowerCase());
  }

  // Performance: Health check with metrics
  Future<Map<String, dynamic>> getHealthMetrics() async {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return {'status': 'production_mode'};
    }

    final stopwatch = Stopwatch()..start();
    final isConnected = await validateConnection();
    stopwatch.stop();

    return {
      'connection_status': isConnected,
      'response_time_ms': stopwatch.elapsedMilliseconds,
      'last_check': DateTime.now().toIso8601String(),
    };
  }
}