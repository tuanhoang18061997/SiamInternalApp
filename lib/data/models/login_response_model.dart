import '../../domain/entities/login_response.dart';

class LoginResponseModel {
  LoginResponseModel({
    required this.token,
    required this.displayName,
    required this.role,
    required this.employeeId,
    required this.canApprove,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'],
      displayName: json['displayName'],
      role: json['role'],
      employeeId: json['employeeId'],
      canApprove: json['canApprove'] ?? false,
    );
  }
  final String token;
  final String displayName;
  final String role;
  final int employeeId;
  final bool canApprove;

  LoginResponse toEntity() => LoginResponse(
        token: token,
        displayName: displayName,
        role: role,
        employeeId: employeeId,
        canApprove: canApprove,
      );
}
