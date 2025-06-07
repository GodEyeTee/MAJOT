part of 'room_bloc.dart';

abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomLoaded extends RoomState {
  final List<Room> rooms;
  final List<Room>? allRooms;
  final RoomStatus? selectedStatus;

  const RoomLoaded(this.rooms, {this.allRooms, this.selectedStatus});

  @override
  List<Object?> get props => [rooms, allRooms, selectedStatus];
}

class RoomDetailLoaded extends RoomState {
  final Room room;

  const RoomDetailLoaded(this.room);

  @override
  List<Object> get props => [room];
}

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  @override
  List<Object> get props => [message];
}
