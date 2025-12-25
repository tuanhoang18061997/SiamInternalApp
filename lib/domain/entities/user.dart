class User {
  final String id;
  final String name;
  final int roleId;

  User({required this.id, required this.name, required this.roleId});

  bool get isManager => roleId == 1 || roleId == 2;
}
