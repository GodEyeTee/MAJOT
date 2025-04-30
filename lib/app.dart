// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/hotel_booking/presentation/pages/hotel_search_page.dart';
import 'features/shopping/presentation/pages/products_page.dart';
import 'features/ocr_scanner/presentation/pages/scanner_page.dart';
import 'screens/main_screen.dart';
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
        // Add other global BLoCs here
      ],
      child: Builder(
        builder: (context) {
          final authBloc = BlocProvider.of<AuthBloc>(context);
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const MainScreen(),
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginPage(),
              ),
              GoRoute(
                path: '/hotel',
                builder: (context, state) => const HotelSearchPage(),
              ),
              GoRoute(
                path: '/shop',
                builder: (context, state) => const ProductsPage(),
              ),
              GoRoute(
                path: '/scanner',
                builder: (context, state) => const ScannerPage(),
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

          return MaterialApp.router(
            title: 'Modular App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
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
