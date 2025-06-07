import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/usecases/bill/get_bills_by_tenant.dart';
import '../../../domain/usecases/bill/create_bill.dart';
import '../../../domain/usecases/bill/calculate_bill.dart';

part 'bill_event.dart';
part 'bill_state.dart';

class BillBloc extends Bloc<BillEvent, BillState> {
  final GetBillsByTenant getBillsByTenant;
  final CreateBill createBill;
  final CalculateBill calculateBill;

  BillBloc({
    required this.getBillsByTenant,
    required this.createBill,
    required this.calculateBill,
  }) : super(BillInitial()) {
    on<LoadBillsByTenantEvent>(_onLoadBillsByTenant);
    on<CreateBillEvent>(_onCreateBill);
    on<CalculateBillEvent>(_onCalculateBill);
  }

  Future<void> _onLoadBillsByTenant(
    LoadBillsByTenantEvent event,
    Emitter<BillState> emit,
  ) async {
    emit(BillLoading());

    final result = await getBillsByTenant(event.tenantId);

    result.fold(
      (failure) => emit(BillError(failure.message)),
      (bills) => emit(BillsLoaded(bills)),
    );
  }

  Future<void> _onCreateBill(
    CreateBillEvent event,
    Emitter<BillState> emit,
  ) async {
    emit(BillSaving());

    final result = await createBill(CreateBillParams(bill: event.bill));

    result.fold(
      (failure) => emit(BillError(failure.message)),
      (bill) => emit(BillSaved(bill)),
    );
  }

  Future<void> _onCalculateBill(
    CalculateBillEvent event,
    Emitter<BillState> emit,
  ) async {
    emit(BillCalculating());

    final result = await calculateBill(
      CalculateBillParams(tenantId: event.tenantId, month: event.month),
    );

    result.fold(
      (failure) => emit(BillError(failure.message)),
      (calculation) => emit(BillCalculated(calculation)),
    );
  }
}
