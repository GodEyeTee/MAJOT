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
import '../core/services/logger_service.dart';
import 'widgets/navigation_drawer.dart' as custom_drawer;
import 'widgets/main_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final RBACService _rbacService = RBACService();
  late List<NavigationItem> _allNavigationItems;
  List<NavigationItem> _visibleNavigationItems = [];

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    _performSecurityCheck();
  }

  void _initializeNavigation() {
    _allNavigationItems = [
      NavigationItem(
        id: 'home',
        icon: Icons.home,
        activeIcon: Icons.home,
        label: 'Home',
        page: const HomePage(),
        permissions: [],
        category: NavigationCategory.primary,
        priority: 100,
        description: 'Dashboard and overview',
      ),
      NavigationItem(
        id: 'hotels',
        icon: Icons.hotel_outlined,
        activeIcon: Icons.hotel,
        label: 'Hotels',
        page: const HotelSearchPage(),
        permissions: ['book_hotels'],
        category: NavigationCategory.business,
        priority: 90,
        description: 'Search and book hotels',
      ),
      NavigationItem(
        id: 'shopping',
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
        label: 'Shop',
        page: const ProductsPage(),
        permissions: ['purchase_products'],
        category: NavigationCategory.business,
        priority: 85,
        description: 'Browse and purchase products',
      ),
      NavigationItem(
        id: 'scanner',
        icon: Icons.document_scanner_outlined,
        activeIcon: Icons.document_scanner,
        label: 'Scanner',
        page: const ScannerPage(),
        permissions: ['use_scanner'],
        category: NavigationCategory.tools,
        priority: 70,
        description: 'OCR document scanning',
      ),
      NavigationItem(
        id: 'wallet',
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: 'Wallet',
        page: const WalletPage(),
        permissions: [],
        category: NavigationCategory.financial,
        priority: 80,
        description: 'Manage your wallet and payments',
      ),
      NavigationItem(
        id: 'analytics',
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        label: 'Analytics',
        page: const AnalyticsPage(),
        permissions: ['view_analytics'],
        category: NavigationCategory.advanced,
        priority: 60,
        description: 'View reports and analytics',
      ),
      NavigationItem(
        id: 'settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings',
        page: const SettingsPage(),
        permissions: [],
        category: NavigationCategory.system,
        priority: 50,
        description: 'App settings and preferences',
      ),
    ];

    _updateVisibleNavigationItems();
    _tabController = TabController(
      length: _visibleNavigationItems.length,
      vsync: this,
    );
  }

  void _updateVisibleNavigationItems() {
    _visibleNavigationItems =
        _allNavigationItems.where((item) {
          if (item.permissions.isEmpty) return true;
          return _rbacService.hasAnyPermission(item.permissions);
        }).toList();

    _visibleNavigationItems.sort((a, b) => b.priority.compareTo(a.priority));

    if (_selectedIndex >= _visibleNavigationItems.length) {
      _selectedIndex = 0;
    }

    LoggerService.info(
      'Navigation: ${_visibleNavigationItems.length}/${_allNavigationItems.length} items visible',
      'NAVIGATION',
    );
  }

  void _performSecurityCheck() {
    final previousCount = _visibleNavigationItems.length;
    _updateVisibleNavigationItems();
    final currentCount = _visibleNavigationItems.length;

    if (previousCount != currentCount) {
      _tabController.dispose();
      _tabController = TabController(
        length: _visibleNavigationItems.length,
        vsync: this,
      );
      LoggerService.info(
        'Navigation updated: $previousCount -> $currentCount items',
        'NAVIGATION',
      );
    }
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _visibleNavigationItems.length) {
      final item = _visibleNavigationItems[index];

      if (item.permissions.isNotEmpty &&
          !_rbacService.hasAnyPermission(item.permissions)) {
        _showAccessDeniedMessage(item);
        return;
      }

      setState(() {
        _selectedIndex = index;
      });

      _tabController.animateTo(index);
    }
  }

  void _showAccessDeniedMessage(NavigationItem item) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.security, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Access denied to ${item.label}. Contact your administrator.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () => _showPermissionDetails(item),
        ),
      ),
    );
  }

  void _showPermissionDetails(NavigationItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.security, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Access Requirements'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feature: ${item.label}'),
                const SizedBox(height: 8),
                Text('Description: ${item.description}'),
                const SizedBox(height: 8),
                const Text('Required Permissions:'),
                ...item.permissions.map(
                  (permission) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $permission'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact your administrator to request access to these features.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _refreshUserData() {
    LoggerService.info('Manual refresh triggered by user', 'MAIN_SCREEN');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Refreshing user data...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    context.read<AuthBloc>().add(
      RefreshUserDataEvent(includePermissions: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is Unauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _performSecurityCheck();
              setState(() {});
            }
          });
        }
      },
      builder: (context, state) {
        if (state is! Authenticated) {
          return _buildErrorScreen('Authentication Required');
        }

        if (_visibleNavigationItems.isEmpty) {
          return _buildErrorScreen('No Accessible Features');
        }

        return _buildMainScreen(state);
      },
    );
  }

  Widget _buildMainScreen(Authenticated state) {
    final currentItem = _visibleNavigationItems[_selectedIndex];

    return Scaffold(
      appBar: MainAppBar(
        currentItem: currentItem,
        user: state.user,
        onRefresh: _refreshUserData,
        visibleItemsCount: _visibleNavigationItems.length,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
      drawer: custom_drawer.NavigationDrawer(
        user: state.user,
        visibleNavigationItems: _visibleNavigationItems,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    final currentItem = _visibleNavigationItems[_selectedIndex];

    return PermissionGuard(
      permissionId:
          currentItem.permissions.isNotEmpty
              ? currentItem.permissions.first
              : '',
      fallback: _buildAccessDeniedPage(currentItem),
      child: IndexedStack(
        index: _selectedIndex,
        children: _visibleNavigationItems.map((item) => item.page).toList(),
      ),
    );
  }

  Widget? _buildBottomNavigation() {
    if (_visibleNavigationItems.length <= 1) return null;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
      items:
          _visibleNavigationItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                  tooltip: item.description,
                ),
              )
              .toList(),
    );
  }

  Widget _buildAccessDeniedPage(NavigationItem item) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.orange.shade600),
            const SizedBox(height: 24),
            Text(
              'Access Restricted',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have permission to access ${item.label}.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showPermissionDetails(item),
              icon: const Icon(Icons.info_outline),
              label: const Text('View Requirements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String title) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Please restart the app or contact support.'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class NavigationItem {
  final String id;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
  final List<String> permissions;
  final NavigationCategory category;
  final int priority;
  final String description;
  final bool isVisible;

  const NavigationItem({
    required this.id,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
    this.permissions = const [],
    this.category = NavigationCategory.primary,
    this.priority = 50,
    this.description = '',
    this.isVisible = true,
  });
}

enum NavigationCategory {
  primary,
  business,
  financial,
  tools,
  advanced,
  system,
}

extension NavigationCategoryExtension on NavigationCategory {
  String get displayName {
    switch (this) {
      case NavigationCategory.primary:
        return 'Primary';
      case NavigationCategory.business:
        return 'Business';
      case NavigationCategory.financial:
        return 'Financial';
      case NavigationCategory.tools:
        return 'Tools';
      case NavigationCategory.advanced:
        return 'Advanced';
      case NavigationCategory.system:
        return 'System';
    }
  }
}
