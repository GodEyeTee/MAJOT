import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String userId;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? bio;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.userId,
    this.displayName,
    this.email,
    this.photoUrl,
    this.bio,
    this.phoneNumber,
    this.dateOfBirth,
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    displayName,
    email,
    photoUrl,
    bio,
    phoneNumber,
    dateOfBirth,
    preferences,
    createdAt,
    updatedAt,
  ];
}
