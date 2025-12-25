class LoginResponse {
  final String token;
  final String displayName;
  final String role;
  final int employeeId;

  LoginResponse({
    required this.token,
    required this.displayName,
    required this.role,
    required this.employeeId,
  });
}
