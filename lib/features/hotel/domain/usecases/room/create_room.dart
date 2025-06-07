import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/room.dart';
import '../../repositories/room_repository.dart';

class CreateRoom implements UseCase<Room, CreateRoomParams> {
  final RoomRepository repository;

  CreateRoom(this.repository);

  @override
  Future<Either<Failure, Room>> call(CreateRoomParams params) async {
    return await repository.createRoom(params.room);
  }
}

class CreateRoomParams extends Equatable {
  final Room room;

  const CreateRoomParams({required this.room});

  @override
  List<Object> get props => [room];
}
