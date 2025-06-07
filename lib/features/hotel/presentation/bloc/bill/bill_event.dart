part of 'bill_bloc.dart';

abstract class BillEvent extends Equatable {
  const BillEvent();

  @override
  List<Object> get props => [];
}

class LoadBillsByTenantEvent extends BillEvent {
  final String tenantId;

  const LoadBillsByTenantEvent(this.tenantId);

  @override
  List<Object> get props => [tenantId];
}

class CreateBillEvent extends BillEvent {
  final Bill bill;

  const CreateBillEvent(this.bill);

  @override
  List<Object> get props => [bill];
}

class CalculateBillEvent extends BillEvent {
  final String tenantId;
  final DateTime month;

  const CalculateBillEvent(this.tenantId, this.month);

  @override
  List<Object> get props => [tenantId, month];
}
