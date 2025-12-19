import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  User? get currentUser => state.value;
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository as AuthRepositoryImpl);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).value;
});
