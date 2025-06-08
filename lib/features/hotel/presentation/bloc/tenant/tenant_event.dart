part of 'tenant_bloc.dart';

abstract class TenantEvent extends Equatable {
  const TenantEvent();

  @override
  List<Object> get props => [];
}

class LoadTenantByRoomEvent extends TenantEvent {
  final String roomId;

  const LoadTenantByRoomEvent(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class LoadTenantByUserEvent extends TenantEvent {
  final String userId;

  const LoadTenantByUserEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class CreateTenantEvent extends TenantEvent {
  final Tenant tenant;

  const CreateTenantEvent(this.tenant);

  @override
  List<Object> get props => [tenant];
}

class CreateTenantWithUserEvent extends TenantEvent {
  final Tenant tenant;
  final String userName;
  final String userEmail;
  final String? userPhone;

  const CreateTenantWithUserEvent({
    required this.tenant,
    required this.userName,
    required this.userEmail,
    this.userPhone,
  });

  @override
  List<Object> get props => [tenant, userName, userEmail]; // ไม่ใส่ userPhone
}

class EndTenancyEvent extends TenantEvent {
  final String tenantId;
  final DateTime endDate;

  const EndTenancyEvent(this.tenantId, this.endDate);

  @override
  List<Object> get props => [tenantId, endDate];
}
