import 'package:equatable/equatable.dart';
import '../../../../services/rbac/role_manager.dart';

class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final UserRole role;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.role = UserRole.user,
  });

  @override
  List<Object?> get props => [id, email, displayName, role];
}
