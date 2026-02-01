import '../../domain/entities/login_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remote);
  final AuthRemoteDataSource remote;

  @override
  Future<LoginResponse?> login(String username, String password) async {
    final model = await remote.login(username, password);
    return model?.toEntity(); // nếu sai thì null
  }

  @override
  Future<void> logout() async {
    // Xoá token local nếu cần
  }

  @override
  Future<LoginResponse?> getCurrentUser() async {
    return null;
  }
}
