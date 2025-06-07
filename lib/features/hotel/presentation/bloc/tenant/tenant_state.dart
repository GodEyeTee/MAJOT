part of 'tenant_bloc.dart';

abstract class TenantState extends Equatable {
  const TenantState();

  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {}

class TenantLoading extends TenantState {}

class TenantSaving extends TenantState {}

class TenantLoaded extends TenantState {
  final Tenant? tenant;

  const TenantLoaded(this.tenant);

  @override
  List<Object?> get props => [tenant];
}

class TenantSaved extends TenantState {
  final Tenant tenant;

  const TenantSaved(this.tenant);

  @override
  List<Object> get props => [tenant];
}

class TenancyEnded extends TenantState {}

class TenantError extends TenantState {
  final String message;

  const TenantError(this.message);

  @override
  List<Object> get props => [message];
}
