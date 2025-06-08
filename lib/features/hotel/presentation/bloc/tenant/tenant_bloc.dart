import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/usecases/tenant/get_tenant_by_room.dart';
import '../../../domain/usecases/tenant/get_tenant_by_user.dart';
import '../../../domain/usecases/tenant/create_tenant.dart';
import '../../../domain/usecases/tenant/end_tenancy.dart';

part 'tenant_event.dart';
part 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final GetTenantByRoom getTenantByRoom;
  final GetTenantByUser getTenantByUser;
  final CreateTenant createTenant;
  final EndTenancy endTenancy;

  TenantBloc({
    required this.getTenantByRoom,
    required this.getTenantByUser,
    required this.createTenant,
    required this.endTenancy,
  }) : super(TenantInitial()) {
    on<LoadTenantByRoomEvent>(_onLoadTenantByRoom);
    on<LoadTenantByUserEvent>(_onLoadTenantByUser);
    on<CreateTenantEvent>(_onCreateTenant);
    on<CreateTenantWithUserEvent>(_onCreateTenantWithUser);
    on<EndTenancyEvent>(_onEndTenancy);
  }

  Future<void> _onLoadTenantByRoom(
    LoadTenantByRoomEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantLoading());

    final result = await getTenantByRoom(event.roomId);

    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (tenant) => emit(TenantLoaded(tenant)),
    );
  }

  Future<void> _onLoadTenantByUser(
    LoadTenantByUserEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantLoading());

    final result = await getTenantByUser(event.userId);

    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (tenant) => emit(TenantLoaded(tenant)),
    );
  }

  Future<void> _onCreateTenant(
    CreateTenantEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantSaving());

    final result = await createTenant(CreateTenantParams(tenant: event.tenant));

    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (tenant) => emit(TenantSaved(tenant)),
    );
  }

  Future<void> _onCreateTenantWithUser(
    CreateTenantWithUserEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantSaving());

    try {
      final result = await createTenant(
        CreateTenantParams(tenant: event.tenant),
      );

      result.fold(
        (failure) => emit(TenantError(failure.message)),
        (tenant) => emit(TenantSaved(tenant)),
      );
    } catch (e) {
      emit(TenantError(e.toString()));
    }
  }

  Future<void> _onEndTenancy(
    EndTenancyEvent event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantSaving());

    final result = await endTenancy(
      EndTenancyParams(tenantId: event.tenantId, endDate: event.endDate),
    );

    result.fold(
      (failure) => emit(TenantError(failure.message)),
      (_) => emit(TenancyEnded()),
    );
  }
}
