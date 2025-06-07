part of 'room_bloc.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoomsEvent extends RoomEvent {}

class LoadRoomEvent extends RoomEvent {
  final String roomId;

  const LoadRoomEvent(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class CreateRoomEvent extends RoomEvent {
  final Room room;

  const CreateRoomEvent(this.room);

  @override
  List<Object> get props => [room];
}

class UpdateRoomEvent extends RoomEvent {
  final Room room;

  const UpdateRoomEvent(this.room);

  @override
  List<Object> get props => [room];
}

class DeleteRoomEvent extends RoomEvent {
  final String roomId;

  const DeleteRoomEvent(this.roomId);

  @override
  List<Object> get props => [roomId];
}

class FilterRoomsByStatusEvent extends RoomEvent {
  final RoomStatus? status;

  const FilterRoomsByStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}
