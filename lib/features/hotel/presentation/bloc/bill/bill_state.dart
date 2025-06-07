part of 'bill_bloc.dart';

abstract class BillState extends Equatable {
  const BillState();

  @override
  List<Object?> get props => [];
}

class BillInitial extends BillState {}

class BillLoading extends BillState {}

class BillSaving extends BillState {}

class BillCalculating extends BillState {}

class BillsLoaded extends BillState {
  final List<Bill> bills;

  const BillsLoaded(this.bills);

  @override
  List<Object> get props => [bills];
}

class BillSaved extends BillState {
  final Bill bill;

  const BillSaved(this.bill);

  @override
  List<Object> get props => [bill];
}

class BillCalculated extends BillState {
  final Map<String, dynamic> calculation;

  const BillCalculated(this.calculation);

  @override
  List<Object> get props => [calculation];
}

class BillError extends BillState {
  final String message;

  const BillError(this.message);

  @override
  List<Object> get props => [message];
}
