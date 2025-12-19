class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? department;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
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

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? department,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
    );
  }
}
