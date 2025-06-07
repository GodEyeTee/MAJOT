import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/bill_model.dart';

abstract class BillRemoteDataSource {
  Future<List<BillModel>> getBills();
  Future<BillModel> getBill(String id);
  Future<List<BillModel>> getBillsByTenant(String tenantId);
  Future<List<BillModel>> getBillsByRoom(String roomId);
  Future<BillModel> createBill(BillModel bill);
  Future<BillModel> updateBill(BillModel bill);
  Future<List<BillModel>> getUnpaidBills();
  Future<List<BillModel>> getOverdueBills();
  Future<Map<String, dynamic>> calculateBill(String tenantId, DateTime month);
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final SupabaseClient supabaseClient;

  BillRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<BillModel>> getBills() async {
    try {
      final response = await supabaseClient
          .from('bills')
          .select()
          .order('bill_month', ascending: false);

      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get bills: $e');
    }
  }

  @override
  Future<BillModel> getBill(String id) async {
    try {
      final response =
          await supabaseClient.from('bills').select().eq('id', id).single();

      return BillModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to get bill: $e');
    }
  }

  @override
  Future<List<BillModel>> getBillsByTenant(String tenantId) async {
    try {
      final response = await supabaseClient
          .from('bills')
          .select()
          .eq('tenant_id', tenantId)
          .order('bill_month', ascending: false);

      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get tenant bills: $e');
    }
  }

  @override
  Future<List<BillModel>> getBillsByRoom(String roomId) async {
    try {
      final response = await supabaseClient
          .from('bills')
          .select()
          .eq('room_id', roomId)
          .order('bill_month', ascending: false);

      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get room bills: $e');
    }
  }

  @override
  Future<BillModel> createBill(BillModel bill) async {
    try {
      final data = bill.toJson()..remove('id');
      final response =
          await supabaseClient.from('bills').insert(data).select().single();

      return BillModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create bill: $e');
    }
  }

  @override
  Future<BillModel> updateBill(BillModel bill) async {
    try {
      final data = bill.toJson()..remove('created_at');

      final response =
          await supabaseClient
              .from('bills')
              .update(data)
              .eq('id', bill.id)
              .select()
              .single();

      return BillModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update bill: $e');
    }
  }

  @override
  Future<List<BillModel>> getUnpaidBills() async {
    try {
      final response = await supabaseClient
          .from('bills')
          .select()
          .eq('payment_status', 'pending')
          .order('due_date');

      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get unpaid bills: $e');
    }
  }

  @override
  Future<List<BillModel>> getOverdueBills() async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabaseClient
          .from('bills')
          .select()
          .eq('payment_status', 'pending')
          .lt('due_date', now)
          .order('due_date');

      return (response as List)
          .map((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get overdue bills: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> calculateBill(
    String tenantId,
    DateTime month,
  ) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      final response = await supabaseClient.rpc(
        'calculate_bill',
        params: {'p_tenant_id': tenantId, 'p_month': monthStr},
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw ServerException('Failed to calculate bill: $e');
    }
  }
}
