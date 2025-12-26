import '../entities/login_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this.repository);
  final AuthRepository repository;

  Future<LoginResponse?> call(String username, String password) {
    return repository.login(username, password);
  }
}
