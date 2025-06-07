import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_remote_data_source.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource remoteDataSource;

  RoomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Room>>> getRooms() async {
    try {
      final rooms = await remoteDataSource.getRooms();
      return Right(rooms);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Room>> getRoom(String id) async {
    try {
      final room = await remoteDataSource.getRoom(id);
      return Right(room);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Room>> createRoom(Room room) async {
    try {
      final roomModel = RoomModel(
        id: room.id,
        roomNumber: room.roomNumber,
        floor: room.floor,
        roomType: room.roomType,
        size: room.size,
        monthlyRent: room.monthlyRent,
        status: room.status,
        description: room.description,
        amenities: room.amenities,
        images: room.images,
        createdBy: room.createdBy,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
      );
      final newRoom = await remoteDataSource.createRoom(roomModel);
      return Right(newRoom);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Room>> updateRoom(Room room) async {
    try {
      final roomModel = RoomModel(
        id: room.id,
        roomNumber: room.roomNumber,
        floor: room.floor,
        roomType: room.roomType,
        size: room.size,
        monthlyRent: room.monthlyRent,
        status: room.status,
        description: room.description,
        amenities: room.amenities,
        images: room.images,
        createdBy: room.createdBy,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
      );
      final updatedRoom = await remoteDataSource.updateRoom(roomModel);
      return Right(updatedRoom);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String id) async {
    try {
      await remoteDataSource.deleteRoom(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getRoomsByStatus(
    RoomStatus status,
  ) async {
    try {
      final rooms = await remoteDataSource.getRoomsByStatus(status.value);
      return Right(rooms);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getAvailableRooms() async {
    try {
      final rooms = await remoteDataSource.getRoomsByStatus(
        RoomStatus.available.value,
      );
      return Right(rooms);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
