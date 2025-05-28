import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Core Dependencies
import 'core/di/injection_container.dart' as di;
import 'core/themes/app_theme.dart';
// Features
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/hotel_booking/presentation/pages/hotel_search_page.dart';
import 'features/shopping/presentation/pages/products_page.dart';
import 'features/ocr_scanner/presentation/pages/scanner_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
// Main Screen
import 'screens/main_screen.dart';
// Services
import 'services/rbac/role_based_router.dart';
// Utils
import 'dart:async';

/// Security-First Flutter App with Clean Architecture
/// Implements RBAC, Secure Routing, and Performance Monitoring
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
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: _handleAuthStateChanges,
        builder: (context, authState) {
          // Security: Show secure loading during initialization
          if (!context.read<AuthBloc>().isInitialized &&
              authState is! AuthError) {
            return _buildSecureLoadingApp();
          }

          // Build main app with security context
          return _buildMainApp(context, authState);
        },
      ),
    );
  }

  /// Handle authentication state changes with security logging
  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (!kReleaseMode) {
      switch (state.runtimeType) {
        case Authenticated:
          final authState = state as Authenticated;
          print('🔐 User authenticated: ${authState.user?.email}');
          print('🎭 User role: ${authState.user?.role}');
          break;
        case Unauthenticated:
          print('👤 User signed out');
          break;
        case AuthError:
          final errorState = state as AuthError;
          print('❌ Auth error: ${errorState.message}');
          break;
      }
    }
  }

  /// Build secure loading screen
  Widget _buildSecureLoadingApp() {
    return MaterialApp(
      title: 'Secure App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SecureLoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Build main application with routing and security
  Widget _buildMainApp(BuildContext context, AuthState authState) {
    print('🟢 Current auth state: ${authState.runtimeType}');
    print('🟢 Building router for state: ${authState.runtimeType}');

    final router = _createSecureRouter(context, authState);

    return MaterialApp.router(
      title: 'Secure Modular App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Performance: Disable unnecessary rebuilds
      builder: (context, child) {
        return MediaQuery(
          // Security: Disable text scaling for consistent UI
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Create secure router with RBAC and performance monitoring
  GoRouter _createSecureRouter(BuildContext context, AuthState authState) {
    final authBloc = context.read<AuthBloc>();

    return GoRouter(
      initialLocation: '/',
      // Performance: Enable router logging in debug mode
      debugLogDiagnostics: kDebugMode,

      routes: [
        // Public Routes
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),

        // Protected Routes with RBAC
        GoRoute(
          path: '/hotel',
          name: 'hotel',
          builder:
              (context, state) => _buildSecureRoute(
                context: context,
                state: state,
                builder: (context, state) => const HotelSearchPage(),
                requiredPermissions: ['book_hotels'],
                routeName: 'Hotel Booking',
              ),
        ),
        GoRoute(
          path: '/shop',
          name: 'shop',
          builder:
              (context, state) => _buildSecureRoute(
                context: context,
                state: state,
                builder: (context, state) => const ProductsPage(),
                requiredPermissions: ['purchase_products'],
                routeName: 'Shopping',
              ),
        ),
        GoRoute(
          path: '/scanner',
          name: 'scanner',
          builder:
              (context, state) => _buildSecureRoute(
                context: context,
                state: state,
                builder: (context, state) => const ScannerPage(),
                requiredPermissions: ['use_scanner'],
                routeName: 'OCR Scanner',
              ),
        ),
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder:
              (context, state) => _buildSecureRoute(
                context: context,
                state: state,
                builder: (context, state) => const AnalyticsPage(),
                requiredPermissions: ['view_analytics'],
                routeName: 'Analytics',
              ),
        ),

        // Semi-Protected Routes (accessible to all authenticated users)
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],

      // Security: Comprehensive redirect logic
      redirect: (BuildContext context, GoRouterState state) {
        return _handleSecureRedirect(context, state, authBloc, authState);
      },

      // Performance: Efficient router refresh
      refreshListenable: SecureRouterRefreshStream(authBloc.stream),

      // Security: Global error handling
      errorBuilder: (context, state) => _buildErrorPage(context, state),
    );
  }

  /// Build secure route with permission checking
  Widget _buildSecureRoute({
    required BuildContext context,
    required GoRouterState state,
    required Widget Function(BuildContext, GoRouterState) builder,
    required List<String> requiredPermissions,
    required String routeName,
  }) {
    return buildWithPermissionCheck(
      context: context,
      state: state,
      builder: builder,
      requiredPermissions: requiredPermissions,
      unauthorizedBuilder:
          (context) => _buildUnauthorizedPage(context, routeName),
    );
  }

  /// Handle secure redirects with logging
  String? _handleSecureRedirect(
    BuildContext context,
    GoRouterState state,
    AuthBloc authBloc,
    AuthState authState,
  ) {
    // Performance: Early return if not initialized
    if (!authBloc.isInitialized) {
      return null; // Let loading screen handle this
    }

    final isAuthenticated = authState is Authenticated;
    final currentPath = state.matchedLocation;
    final isLoginRoute = currentPath == '/login';

    // Security: Log routing attempts in debug mode
    if (!kReleaseMode) {
      print('🛣️ Route access attempt: $currentPath');
      print('🔐 Authentication status: $isAuthenticated');
    }

    // Security: Force authentication for protected routes
    if (!isAuthenticated && !isLoginRoute) {
      if (!kReleaseMode) {
        print('🚫 Redirecting unauthenticated user to login');
      }
      return '/login';
    }

    // UX: Redirect authenticated users away from login
    if (isAuthenticated && isLoginRoute) {
      if (!kReleaseMode) {
        print('✅ Redirecting authenticated user to home');
      }
      return '/';
    }

    // Performance: No redirect needed
    return null;
  }

  /// Build unauthorized access page
  Widget _buildUnauthorizedPage(BuildContext context, String routeName) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 80, color: Colors.orange.shade600),
              const SizedBox(height: 24),
              Text(
                'Access Restricted',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You don\'t have permission to access $routeName.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your administrator to request access.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build router error page
  Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    final error = state.error?.toString() ?? 'Unknown routing error';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Error'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade600),
              const SizedBox(height: 24),
              Text(
                'Navigation Error',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The requested page could not be found or accessed.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (!kReleaseMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Debug: $error',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secure loading screen with progress indication
class SecureLoadingScreen extends StatefulWidget {
  const SecureLoadingScreen({super.key});

  @override
  State<SecureLoadingScreen> createState() => _SecureLoadingScreenState();
}

class _SecureLoadingScreenState extends State<SecureLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Title
                    Text(
                      'Secure App',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading Text
                    Text(
                      'Initializing Security Services...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Security Features List
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          _buildSecurityFeature('🔐 Authentication Services'),
                          _buildSecurityFeature(
                            '🛡️ Role-Based Access Control',
                          ),
                          _buildSecurityFeature(
                            '🔗 Secure Database Connection',
                          ),
                          _buildSecurityFeature('📊 Performance Monitoring'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            feature,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Router Refresh Stream with error handling and performance monitoring
class SecureRouterRefreshStream extends ChangeNotifier {
  final Stream<dynamic> _stream;
  late final StreamSubscription<dynamic> _subscription;
  int _refreshCount = 0;
  DateTime? _lastRefresh;

  SecureRouterRefreshStream(this._stream) {
    _subscription = _stream.asBroadcastStream().listen(
      _handleStreamEvent,
      onError: _handleStreamError,
      onDone: _handleStreamDone,
    );
  }

  void _handleStreamEvent(dynamic event) {
    try {
      _refreshCount++;
      _lastRefresh = DateTime.now();

      if (!kReleaseMode) {
        print(
          '🔄 Router refresh #$_refreshCount triggered by auth state change',
        );
      }

      notifyListeners();
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Router refresh error: $e');
      }
    }
  }

  void _handleStreamError(dynamic error) {
    if (!kReleaseMode) {
      print('❌ Auth stream error: $error');
    }
    // Continue listening despite errors
  }

  void _handleStreamDone() {
    if (!kReleaseMode) {
      print('🔚 Auth stream completed');
    }
  }

  // Performance monitoring getters
  int get refreshCount => _refreshCount;
  DateTime? get lastRefresh => _lastRefresh;

  @override
  void dispose() {
    if (!kReleaseMode) {
      print('🧹 Router refresh stream disposed after $_refreshCount refreshes');
    }
    _subscription.cancel();
    super.dispose();
  }
}
