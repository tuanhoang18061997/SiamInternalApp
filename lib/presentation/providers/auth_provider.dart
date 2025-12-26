import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/network/dio_client.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<AsyncValue<LoginResponse?>> {
  AuthNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));
  final AuthRepository _repository;
  final Ref _ref;

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.login(username, password);

      if (response != null) {
        _ref.read(authTokenProvider.notifier).state = response.token;
        state = AsyncValue.data(response);
      } else {
        // Sai tài khoản hoặc mật khẩu → chỉ set error string
        state = AsyncValue.error(
          'Sai tài khoản hoặc mật khẩu',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      // Lỗi khác (network, server)
      state = AsyncValue.error(e.toString(), stack);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _ref.read(authTokenProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }

  LoginResponse? get currentUser => state.value;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remote = AuthRemoteDataSource(dio);
  return AuthRepositoryImpl(remote);
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<LoginResponse?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});

final currentUserProvider = Provider<LoginResponse?>((ref) {
  return ref.watch(authProvider).value;
});
