import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service_client.dart';
import '../models/user_model.dart';

abstract class SupabaseUserDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String id);
  Future<void> updateUserRole(String id, String role);
  Future<bool> validateConnection();
  Future<Map<String, dynamic>> getHealthMetrics();
}

class SupabaseUserDataSourceImpl implements SupabaseUserDataSource {
  final SupabaseServiceClient _serviceClient;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _operationTimeout = Duration(seconds: 10);

  SupabaseUserDataSourceImpl({SupabaseServiceClient? serviceClient})
    : _serviceClient = serviceClient ?? SupabaseServiceClient();

  /// Get service client instance
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
        print('📝 Saving user with service client: ${user.email}');
        print('   User ID: ${user.id}');
        print('   Role: ${user.role}');

        // ใช้ service client ที่ bypass RLS
        await _client
            .from('users')
            .upsert(userData, onConflict: 'id')
            .timeout(_operationTimeout);

        if (!_isProduction) {
          print('✅ User saved successfully: ${user.email}');
        }
      } on PostgrestException catch (e) {
        print('❌ Postgrest error saving user: ${e.code} - ${e.message}');

        // Handle specific errors
        if (e.code == '23505') {
          // Duplicate key - try update
          try {
            await _client
                .from('users')
                .update({
                  'full_name': userData['full_name'],
                  'role': userData['role'], // อัพเดต role ด้วย
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', user.id)
                .timeout(_operationTimeout);

            if (!_isProduction) {
              print('✅ User updated successfully: ${user.email}');
            }
            return;
          } catch (updateError) {
            print('❌ Update also failed: $updateError');
            throw DatabaseException(
              'Failed to save or update user: $updateError',
            );
          }
        }
        throw DatabaseException(_handlePostgrestError(e));
      } on Exception catch (e) {
        print('❌ Unknown error saving user: $e');
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
        print('🔍 Getting user with service client: $id');

        // ใช้ service client ที่ bypass RLS
        final response = await _client
            .from('users')
            .select()
            .eq('id', id)
            .maybeSingle()
            .timeout(_operationTimeout);

        if (response == null) {
          print('❌ No user found with ID: $id');
          return null;
        }

        print('✅ Found user in Supabase:');
        print('   Email: ${response['email']}');
        print('   Role: ${response['role']}');
        print('   Full Name: ${response['full_name']}');

        _validateUserData(response);
        final userModel = UserModel.fromJson(response);

        print('✅ User model created with role: ${userModel.role}');
        return userModel;
      } on PostgrestException catch (e) {
        print('❌ Postgrest error getting user: ${e.code} - ${e.message}');
        if (e.code == 'PGRST116') return null;
        throw DatabaseException(_handlePostgrestError(e));
      } on Exception catch (e) {
        print('❌ Unknown error getting user: $e');
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
        print('🔄 Updating user role with service client:');
        print('   User ID: $id');
        print('   New Role: $role');

        // ใช้ service client ที่ bypass RLS
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

        if (!_isProduction) {
          print('✅ User role updated: $id -> $role');
        }
      } on PostgrestException catch (e) {
        print('❌ Postgrest error updating role: ${e.code} - ${e.message}');
        throw DatabaseException(_handlePostgrestError(e));
      } on Exception catch (e) {
        print('❌ Unknown error updating role: $e');
        throw DatabaseException('Role update failed: ${e.toString()}');
      }
    });
  }

  @override
  Future<bool> validateConnection() async {
    try {
      if (!_serviceClient.isInitialized) {
        if (!_isProduction) {
          print('❌ Service client not initialized');
        }
        return false;
      }

      // Test service client connection
      final isValid = await _serviceClient.testConnection();

      if (!_isProduction) {
        print(
          isValid
              ? '✅ Supabase service connection validated'
              : '❌ Supabase service connection failed',
        );
      }

      return isValid;
    } catch (e) {
      if (!_isProduction) {
        print('⚠️ Supabase service connection validation failed: $e');
      }
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getHealthMetrics() async {
    if (_isProduction) {
      return {
        'status': 'production_mode',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    final stopwatch = Stopwatch()..start();
    final isConnected = await validateConnection();
    stopwatch.stop();

    return {
      'connection_status': isConnected ? 'healthy' : 'unhealthy',
      'response_time_ms': stopwatch.elapsedMilliseconds,
      'last_check': DateTime.now().toIso8601String(),
      'client_type': 'service_role_client',
      'bypass_rls': true,
      'service_client_health': _serviceClient.getHealthStatus(),
      'retry_config': {
        'max_retries': _maxRetries,
        'retry_delay_ms': _retryDelay.inMilliseconds,
        'operation_timeout_ms': _operationTimeout.inMilliseconds,
      },
      'performance_metrics': {
        'avg_query_time': '${stopwatch.elapsedMilliseconds}ms',
        'connection_pool': 'service_role',
      },
    };
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
          if (!_isProduction) {
            print('ℹ️ User already exists, not retrying');
          }
          return await operation();
        }

        if (attempts >= _maxRetries) {
          if (!_isProduction) {
            print('❌ Operation failed after $_maxRetries attempts: $e');
          }
          rethrow;
        }

        final jitter = Duration(
          milliseconds: (currentDelay.inMilliseconds * 0.1).round(),
        );
        final delayWithJitter = currentDelay + jitter;

        if (!_isProduction) {
          print(
            '🔄 Retry attempt $attempts after ${delayWithJitter.inMilliseconds}ms',
          );
        }

        await Future.delayed(delayWithJitter);
        currentDelay *= 2;
      }
    }

    throw const DatabaseException(
      'Operation failed after maximum retry attempts',
    );
  }

  String _handlePostgrestError(PostgrestException e) {
    if (!_isProduction) {
      print('🔴 Postgrest Error: ${e.code} - ${e.message}');
      print('🔴 Error details: ${e.details}');
    }

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

  bool get _isProduction => const bool.fromEnvironment('dart.vm.product');

  Future<Map<String, dynamic>> getConnectionPoolStatus() async {
    if (_isProduction) {
      return {'status': 'production_mode'};
    }

    try {
      final connectionStart = DateTime.now();
      final isConnected = await validateConnection();
      final connectionEnd = DateTime.now();
      final latency = connectionEnd.difference(connectionStart);

      return {
        'pool_status': isConnected ? 'healthy' : 'degraded',
        'latency_ms': latency.inMilliseconds,
        'connection_quality': _getConnectionQuality(latency.inMilliseconds),
        'timestamp': connectionEnd.toIso8601String(),
        'client_info': {
          'ready': _serviceClient.isInitialized,
          'authenticated': true,
          'type': 'service_role',
        },
      };
    } catch (e) {
      return {
        'pool_status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'client_info': {
          'ready': false,
          'authenticated': false,
          'type': 'service_role',
        },
      };
    }
  }

  String _getConnectionQuality(int latencyMs) {
    if (latencyMs < 100) return 'excellent';
    if (latencyMs < 300) return 'good';
    if (latencyMs < 1000) return 'fair';
    return 'poor';
  }

  Future<void> dispose() async {
    if (!_isProduction) {
      print('🧹 SupabaseUserDataSource disposed');
    }
  }
}
