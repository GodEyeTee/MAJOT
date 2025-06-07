import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/room.dart';

abstract class RoomRepository {
  Future<Either<Failure, List<Room>>> getRooms();
  Future<Either<Failure, Room>> getRoom(String id);
  Future<Either<Failure, Room>> createRoom(Room room);
  Future<Either<Failure, Room>> updateRoom(Room room);
  Future<Either<Failure, void>> deleteRoom(String id);
  Future<Either<Failure, List<Room>>> getRoomsByStatus(RoomStatus status);
  Future<Either<Failure, List<Room>>> getAvailableRooms();
}
