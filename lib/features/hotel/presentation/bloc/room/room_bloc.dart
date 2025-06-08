import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/room.dart';
import '../../../domain/usecases/room/get_rooms.dart';
import '../../../domain/usecases/room/create_room.dart';

part 'room_event.dart';
part 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final GetRooms getRooms;
  final CreateRoom createRoom;

  RoomBloc({required this.getRooms, required this.createRoom})
    : super(RoomInitial()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<LoadRoomEvent>(_onLoadRoom);
    on<CreateRoomEvent>(_onCreateRoom);
    on<UpdateRoomEvent>(_onUpdateRoom);
    on<DeleteRoomEvent>(_onDeleteRoom);
    on<FilterRoomsByStatusEvent>(_onFilterRoomsByStatus);
  }

  Future<void> _onLoadRooms(
    LoadRoomsEvent event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    final result = await getRooms(NoParams());

    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (rooms) => emit(RoomLoaded(rooms)),
    );
  }

  Future<void> _onLoadRoom(LoadRoomEvent event, Emitter<RoomState> emit) async {
    emit(RoomLoading());

    try {
      final result = await getRooms(NoParams());

      result.fold((failure) => emit(RoomError(failure.message)), (rooms) {
        final room = rooms.firstWhere(
          (r) => r.id == event.roomId,
          orElse: () => throw Exception('Room not found'),
        );
        emit(RoomDetailLoaded(room));
      });
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onCreateRoom(
    CreateRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());

    final result = await createRoom(CreateRoomParams(room: event.room));

    result.fold((failure) => emit(RoomError(failure.message)), (room) {
      add(LoadRoomsEvent());
    });
  }

  Future<void> _onUpdateRoom(
    UpdateRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    // TODO: Implement update room
    emit(RoomError('Update room not implemented'));
  }

  Future<void> _onDeleteRoom(
    DeleteRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    // TODO: Implement delete room
    emit(RoomError('Delete room not implemented'));
  }

  Future<void> _onFilterRoomsByStatus(
    FilterRoomsByStatusEvent event,
    Emitter<RoomState> emit,
  ) async {
    if (state is RoomLoaded) {
      final currentState = state as RoomLoaded;
      final filteredRooms =
          event.status == null
              ? currentState.allRooms ?? currentState.rooms
              : (currentState.allRooms ?? currentState.rooms)
                  .where((room) => room.status == event.status)
                  .toList();

      emit(
        RoomLoaded(
          filteredRooms,
          allRooms: currentState.allRooms ?? currentState.rooms,
          selectedStatus: event.status,
        ),
      );
    }
  }
}
