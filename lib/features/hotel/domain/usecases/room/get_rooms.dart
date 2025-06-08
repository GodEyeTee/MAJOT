import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/room.dart';
import '../../repositories/room_repository.dart';

class GetRooms implements UseCase<List<Room>, NoParams> {
  final RoomRepository repository;

  GetRooms(this.repository);

  @override
  Future<Either<Failure, List<Room>>> call(NoParams params) async {
    return await repository.getRooms();
  }
}
