import '../../domain/entities/login_response.dart';

class LoginResponseModel {
  final String token;
  final String displayName;
  final String role;
  final int employeeId;

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

  LoginResponse toEntity() => LoginResponse(
        token: token,
        displayName: displayName,
        role: role,
        employeeId: employeeId,
      );
}
