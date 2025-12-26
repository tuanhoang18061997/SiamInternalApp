import '../../domain/entities/login_response.dart';

class LoginResponseModel {
  LoginResponseModel({
    required this.token,
    required this.displayName,
    required this.role,
    required this.employeeId,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'],
      displayName: json['displayName'],
      role: json['role'],
      employeeId: json['employeeId'],
    );
  }
  final String token;
  final String displayName;
  final String role;
  final int employeeId;

  LoginResponse toEntity() => LoginResponse(
        token: token,
        displayName: displayName,
        role: role,
        employeeId: employeeId,
      );
}
