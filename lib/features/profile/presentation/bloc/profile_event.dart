import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final String userId;

  const LoadProfileEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateProfileEvent extends ProfileEvent {
  final Profile profile;

  const UpdateProfileEvent(this.profile);

  @override
  List<Object> get props => [profile];
}
