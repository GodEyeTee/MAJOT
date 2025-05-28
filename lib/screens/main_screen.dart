import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/wallet/presentation/pages/wallet_page.dart';
import '../features/analytics/presentation/pages/analytics_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/hotel_booking/presentation/pages/hotel_search_page.dart';
import '../features/shopping/presentation/pages/products_page.dart';
import '../features/ocr_scanner/presentation/pages/scanner_page.dart';
import '../services/rbac/rbac_service.dart';
import '../services/rbac/permission_guard.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final RBACService _rbacService = RBACService();

  // Security: Define navigation items with required permissions
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Home',
      page: HomePage(),
      permissions: [], // Home is accessible to all authenticated users
    ),
    NavigationItem(
      icon: Icons.hotel,
      label: 'Hotels',
      page: HotelSearchPage(),
      permissions: ['book_hotels'],
    ),
    NavigationItem(
      icon: Icons.shopping_cart,
      label: 'Shop',
      page: ProductsPage(),
      permissions: ['purchase_products'],
    ),
    NavigationItem(
      icon: Icons.document_scanner,
      label: 'Scanner',
      page: ScannerPage(),
      permissions: ['use_scanner'],
    ),
    NavigationItem(
      icon: Icons.wallet,
      label: 'Wallet',
      page: WalletPage(),
      permissions: [], // Wallet is accessible to all
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analytics',
      page: AnalyticsPage(),
      permissions: ['view_analytics'],
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      page: SettingsPage(),
      permissions: [], // Settings is accessible to all
    ),
  ];

  // Performance: Filter navigation items based on permissions once
  List<NavigationItem> get _allowedNavigationItems {
    return _navigationItems.where((item) {
      if (item.permissions.isEmpty) return true;
      return _rbacService.hasAnyPermission(item.permissions);
    }).toList();
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _allowedNavigationItems.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Authentication Error'),
                  Text('Please restart the app'),
                ],
              ),
            ),
          );
        }

        final allowedItems = _allowedNavigationItems;

        // Security: Ensure selected index is valid
        if (_selectedIndex >= allowedItems.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${allowedItems[_selectedIndex].label} - ${state.user?.role.toString().split('.').last?.toUpperCase() ?? 'USER'}',
            ),
            actions: [
              // Debug Info in Development Mode
              if (const bool.fromEnvironment('dart.vm.product') == false)
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () => _showDebugInfo(context, state),
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showSignOutDialog(context),
              ),
            ],
          ),
          body: PermissionGuard(
            permissionId:
                allowedItems[_selectedIndex].permissions.isNotEmpty
                    ? allowedItems[_selectedIndex].permissions.first
                    : '',
            fallback: _buildAccessDeniedPage(),
            child: allowedItems[_selectedIndex].page,
          ),
          bottomNavigationBar:
              allowedItems.length > 1
                  ? BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _selectedIndex,
                    selectedItemColor: Theme.of(context).primaryColor,
                    unselectedItemColor: Colors.grey,
                    onTap: _onItemTapped,
                    items:
                        allowedItems
                            .map(
                              (item) => BottomNavigationBarItem(
                                icon: Icon(item.icon),
                                label: item.label,
                              ),
                            )
                            .toList(),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildAccessDeniedPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Access Restricted',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('You don\'t have permission to access this feature.'),
          SizedBox(height: 16),
          Text('Contact your administrator to request access.'),
        ],
      ),
    );
  }

  void _showDebugInfo(BuildContext context, Authenticated state) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Debug Information'),
            content: PermissionDebugInfo(),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<AuthBloc>().add(SignOutEvent());
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }
}

// Security: Data class for navigation items with permissions
class NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;
  final List<String> permissions;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
    this.permissions = const [],
  });
}
