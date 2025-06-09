import 'package:my_test_app/core/services/supabase_service_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/tenant_model.dart';

abstract class TenantRemoteDataSource {
  Future<List<TenantModel>> getTenants();
  Future<TenantModel> getTenant(String id);
  Future<TenantModel?> getTenantByRoomId(String roomId);
  Future<TenantModel?> getTenantByUserId(String userId);
  Future<TenantModel> createTenant(TenantModel tenant);
  Future<TenantModel> updateTenant(TenantModel tenant);
  Future<void> endTenancy(String tenantId, DateTime endDate);
  Future<List<TenantModel>> getActiveTenants();
}

class TenantRemoteDataSourceImpl implements TenantRemoteDataSource {
  final SupabaseClient supabaseClient;

  TenantRemoteDataSourceImpl({required this.supabaseClient});
  SupabaseClient get _serviceClient => SupabaseServiceClient().client;

  @override
  Future<List<TenantModel>> getTenants() async {
    try {
      final response = await supabaseClient
          .from('tenants')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TenantModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get tenants: $e');
    }
  }

  @override
  Future<TenantModel> getTenant(String id) async {
    try {
      final response =
          await supabaseClient.from('tenants').select().eq('id', id).single();

      return TenantModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to get tenant: $e');
    }
  }

  @override
  Future<TenantModel?> getTenantByRoomId(String roomId) async {
    try {
      final response =
          await supabaseClient
              .from('tenants')
              .select()
              .eq('room_id', roomId)
              .eq('is_active', true)
              .maybeSingle();

      return response != null ? TenantModel.fromJson(response) : null;
    } catch (e) {
      throw ServerException('Failed to get tenant by room: $e');
    }
  }

  @override
  Future<TenantModel?> getTenantByUserId(String userId) async {
    try {
      final response =
          await supabaseClient
              .from('tenants')
              .select()
              .eq('user_id', userId)
              .eq('is_active', true)
              .maybeSingle();

      return response != null ? TenantModel.fromJson(response) : null;
    } catch (e) {
      throw ServerException('Failed to get tenant by user: $e');
    }
  }

  @override
  Future<TenantModel> createTenant(TenantModel tenant) async {
    try {
      final data = tenant.toJson()..remove('id');
      final response =
          await _serviceClient // เปลี่ยนจาก supabaseClient
              .from('tenants')
              .insert(data)
              .select()
              .single();

      return TenantModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create tenant: $e');
    }
  }

  @override
  Future<TenantModel> updateTenant(TenantModel tenant) async {
    try {
      final data = tenant.toJson()..remove('created_at');

      final response =
          await supabaseClient
              .from('tenants')
              .update(data)
              .eq('id', tenant.id)
              .select()
              .single();

      return TenantModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update tenant: $e');
    }
  }

  @override
  Future<void> endTenancy(String tenantId, DateTime endDate) async {
    try {
      await supabaseClient
          .from('tenants')
          .update({'end_date': endDate.toIso8601String(), 'is_active': false})
          .eq('id', tenantId);
    } catch (e) {
      throw ServerException('Failed to end tenancy: $e');
    }
  }

  @override
  Future<List<TenantModel>> getActiveTenants() async {
    try {
      final response = await supabaseClient
          .from('tenants')
          .select()
          .eq('is_active', true)
          .order('start_date', ascending: false);

      return (response as List)
          .map((json) => TenantModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get active tenants: $e');
    }
  }
}
