import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/leave_request_detail_screen.dart';
import '../presentation/screens/create_leave_request_screen.dart';
import '../presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = authState;
      final isLoginRoute = state.matchedLocation == '/';

      // Nếu đang loading hoặc error thì không redirect
      if (auth.isLoading || auth.hasError) {
        return null;
      }

      final isLoggedIn = auth.value != null;

      if (!isLoggedIn && !isLoginRoute) {
        return '/';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/leave-request/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LeaveRequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        path: '/create-leave-request',
        builder: (context, state) => const CreateLeaveRequestScreen(),
      ),
    ],
  );
});
