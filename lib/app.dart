import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/hotel_booking/presentation/pages/hotel_search_page.dart';
import 'features/shopping/presentation/pages/products_page.dart';
import 'features/ocr_scanner/presentation/pages/scanner_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'screens/main_screen.dart';
import 'services/rbac/role_based_router.dart';
import 'dart:async';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // แสดง Loading Screen ขณะ initialize
          if (!context.read<AuthBloc>().isInitialized &&
              authState is! AuthError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing App...'),
                    ],
                  ),
                ),
              ),
            );
          }

          final router = _createRouter(context, authState);

          return MaterialApp.router(
            title: 'Secure Modular App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(BuildContext context, AuthState authState) {
    final authBloc = context.read<AuthBloc>();

    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        // Protected Routes with Permission Checking
        GoRoute(
          path: '/hotel',
          builder:
              (context, state) => buildWithPermissionCheck(
                context: context,
                state: state,
                builder: (context, state) => const HotelSearchPage(),
                requiredPermissions: ['book_hotels'],
              ),
        ),
        GoRoute(
          path: '/shop',
          builder:
              (context, state) => buildWithPermissionCheck(
                context: context,
                state: state,
                builder: (context, state) => const ProductsPage(),
                requiredPermissions: ['purchase_products'],
              ),
        ),
        GoRoute(
          path: '/scanner',
          builder:
              (context, state) => buildWithPermissionCheck(
                context: context,
                state: state,
                builder: (context, state) => const ScannerPage(),
                requiredPermissions: ['use_scanner'],
              ),
        ),
        GoRoute(
          path: '/analytics',
          builder:
              (context, state) => buildWithPermissionCheck(
                context: context,
                state: state,
                builder: (context, state) => const AnalyticsPage(),
                requiredPermissions: ['view_analytics'],
              ),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        // รอให้ auth initialize เสร็จก่อน
        if (!authBloc.isInitialized) {
          return null; // ยังไม่ redirect อะไร
        }

        final isAuthenticated = authState is Authenticated;
        final isLoginRoute = state.matchedLocation == '/login';

        // Security: Redirect unauthenticated users
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // UX: Redirect authenticated users away from login
        if (isAuthenticated && isLoginRoute) {
          return '/';
        }

        return null;
      },
      refreshListenable: SecureRouterRefreshStream(authBloc.stream),
    );
  }
}

/// Secure Router Refresh Stream with proper error handling
class SecureRouterRefreshStream extends ChangeNotifier {
  final Stream<dynamic> _stream;
  late final StreamSubscription<dynamic> _subscription;

  SecureRouterRefreshStream(this._stream) {
    _subscription = _stream.asBroadcastStream().listen(
      (dynamic _) {
        try {
          notifyListeners();
        } catch (e) {
          // Log error but don't crash the app
          print('Router refresh error: $e');
        }
      },
      onError: (error) {
        print('Auth stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
