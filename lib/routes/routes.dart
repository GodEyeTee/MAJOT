import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../screens/main_screen.dart';
import '../core/di/injection_container.dart' as di;

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      final isAuthenticated = authBloc.state is Authenticated;

      final isLoginRoute = state.location == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => MainScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletPage()),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    refreshListenable: GoRouterRefreshStream(
      BlocProvider.of<AuthBloc>(di.sl<BuildContext>()).stream,
    ),
  );
}

// Helper class to refresh the router when the auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
