import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_api_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockApiDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  User? _currentUser;

  @override
  Future<User> login(String email, String password) async {
    final userModel = await _dataSource.login(email, password);
    _currentUser = userModel.toEntity();
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(mockApiDataSourceProvider));
});
