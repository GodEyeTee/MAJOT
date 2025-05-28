import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'dart:async';

GoRouter createRouter(BuildContext context) {
  final authBloc = BlocProvider.of<AuthBloc>(context);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Center(child: Text('Home')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Center(child: Text('Login')),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authBloc.state is Authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
  );
}

// Helper class to refresh the router when the auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  final Stream<dynamic> _stream;
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(this._stream) {
    _subscription = _stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
