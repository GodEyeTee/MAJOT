import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user.dart';
import '../../../../services/rbac/role_manager.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    super.displayName,
    super.role = UserRole.user,
  });

  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: UserRole.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'role': role.toString().split('.').last,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole userRole = UserRole.user;
    try {
      String roleString = json['role'] ?? 'user';
      userRole = UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == roleString,
        orElse: () => UserRole.user,
      );
    } catch (e) {
      userRole = UserRole.user;
    }

    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['full_name'],
      role: userRole,
    );
  }
}
