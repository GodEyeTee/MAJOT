import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'core/di/injection_container.dart' as di;
import 'core/themes/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'screens/main_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final router = _createRouter(context, state);
          return MaterialApp.router(
            title: 'Secure App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(BuildContext context, AuthState authState) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ],
      redirect: (context, state) {
        final isAuthenticated = authState is Authenticated;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoginRoute) return '/login';
        if (isAuthenticated && isLoginRoute) return '/';
        return null;
      },
      refreshListenable: _RouterRefreshStream(context.read<AuthBloc>().stream),
    );
  }
}

class _RouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  _RouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
