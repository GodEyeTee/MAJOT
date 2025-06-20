class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String role;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.phone,
    required this.role,
    this.isGuest = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      // ลองหาชื่อจากหลายฟิลด์ที่เป็นไปได้
      displayName:
          json['display_name'] ??
          json['full_name'] ??
          json['name'] ??
          json['email']?.split('@').first ??
          'Guest User',
      phone: json['phone'],
      role: json['role'] ?? 'guest',
      isGuest: json['is_guest'] ?? (json['role'] == 'guest'),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
