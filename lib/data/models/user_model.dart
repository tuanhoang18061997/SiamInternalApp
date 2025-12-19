import '../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? department;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        department: json['department'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'department': department,
      };

  User toEntity() => User(
        id: id,
        email: email,
        name: name,
        role: role,
        department: department,
      );
}
