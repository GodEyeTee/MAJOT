import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.id, super.email, super.displayName});

  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': displayName};
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['full_name'],
    );
  }
}
