class User {
  User({required this.id, required this.name, required this.roleId});
  final String id;
  final String name;
  final int roleId;

  bool get isManager => roleId == 1 || roleId == 2;
}
