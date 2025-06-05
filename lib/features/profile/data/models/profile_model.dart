import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.userId,
    super.displayName,
    super.email,
    super.photoUrl,
    super.bio,
    super.phoneNumber,
    super.dateOfBirth,
    super.preferences,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // ข้อมูลจาก profiles table
    final profileData = json;

    // ข้อมูลจาก users table (ถ้ามี join)
    final userData = json['users'] ?? {};

    return ProfileModel(
      userId: profileData['user_id'] ?? '',
      // ดึงข้อมูลจาก users table
      displayName:
          userData['full_name'] ??
          profileData['full_name'] ??
          profileData['display_name'],
      email: userData['email'] ?? profileData['email'],
      photoUrl: userData['photo_url'] ?? profileData['photo_url'],
      phoneNumber: userData['phone_number'] ?? profileData['phone_number'],
      // ข้อมูลจาก profiles table
      bio: profileData['bio'],
      dateOfBirth:
          profileData['date_of_birth'] != null
              ? DateTime.parse(profileData['date_of_birth'])
              : null,
      preferences: profileData['preferences'] ?? {},
      createdAt:
          profileData['created_at'] != null
              ? DateTime.parse(profileData['created_at'])
              : DateTime.now(),
      updatedAt:
          profileData['updated_at'] != null
              ? DateTime.parse(profileData['updated_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'preferences': preferences,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
