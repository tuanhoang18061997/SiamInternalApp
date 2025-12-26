import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/login_response_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this.dio);
  final Dio dio;

  Future<LoginResponseModel?> login(String username, String password) async {
    final response = await dio.post(
      ApiConstants.loginEndpoint,
      data: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      return LoginResponseModel.fromJson(response.data);
    } else if (response.statusCode == 401) {
      // Sai tài khoản hoặc mật khẩu → trả về null
      return null;
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}
