import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_test_app/features/privacy_security/presentation/pages/privacy_security_page.dart';
import 'features/privacy_security/presentation/bloc/security_bloc.dart';
import 'package:my_test_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:my_test_app/features/profile/presentation/pages/profile_page.dart';

import 'core/di/injection_container.dart' as di;
import 'core/themes/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/theme/presentation/bloc/theme_bloc.dart';
import 'features/theme/presentation/bloc/theme_state.dart';
import 'screens/main_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<ThemeBloc>(create: (context) => di.sl<ThemeBloc>()),
        BlocProvider<ProfileBloc>(create: (context) => di.sl<ProfileBloc>()),
        BlocProvider<SecurityBloc>(create: (context) => di.sl<SecurityBloc>()),
      ],
      child: Builder(
        builder: (context) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              // Handle auth state changes without rebuilding router
              if (state is Authenticated) {
                if (_router.routerDelegate.currentConfiguration.uri
                        .toString() ==
                    '/login') {
                  _router.go('/');
                }
              } else if (state is Unauthenticated) {
                _router.go('/login');
              }
            },
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                ThemeMode themeMode = ThemeMode.system;
                if (themeState is ThemeLoaded) {
                  themeMode = themeState.actualThemeMode;
                }

                return MaterialApp.router(
                  title: 'Secure App',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  routerConfig: _router,
                  debugShowCheckedModeBanner: false,
                );
              },
            ),
          );
        },
      ),
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      navigatorKey: GlobalKey<NavigatorState>(),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainScreen(),
          routes: [
            // ใช้ nested routes
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: 'privacy-security',
              builder: (context, state) => const PrivacySecurityPage(),
            ),
          ],
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ],
      redirect: (context, state) {
        try {
          final authBloc = context.read<AuthBloc>();
          final isAuthenticated = authBloc.state is Authenticated;
          final isLoginRoute = state.matchedLocation == '/login';

          if (!isAuthenticated && !isLoginRoute) return '/login';
          if (isAuthenticated && isLoginRoute) return '/';
          return null;
        } catch (e) {
          // If BLoC is not available yet, allow navigation
          return null;
        }
      },
    );
  }

  @override
  void dispose() {
    // Router disposal is handled by MaterialApp.router
    super.dispose();
  }
}
