import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../services/rbac/permission_guard.dart';
import '../main_screen.dart';

// Helper function to create permission-guarded menu items
Widget createPermissionMenuItem({
  required String permissionId,
  required String title,
  required IconData icon,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return PermissionGuard(
    permissionId: permissionId,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    ),
    fallback: ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      onTap: () {
        // Show permission required message
      },
      enabled: false,
    ),
  );
}

class NavigationDrawer extends StatelessWidget {
  final User? user;
  final List<NavigationItem> visibleNavigationItems;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NavigationDrawer({
    super.key,
    required this.user,
    required this.visibleNavigationItems,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerSection(context, 'Navigation', [
                  ...visibleNavigationItems.map(
                    (item) => ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      subtitle: Text(item.description),
                      selected:
                          visibleNavigationItems.indexOf(item) == selectedIndex,
                      onTap: () {
                        Navigator.of(context).pop();
                        onItemTapped(visibleNavigationItems.indexOf(item));
                      },
                    ),
                  ),
                ]),
                const Divider(),
                _buildDrawerSection(context, 'System', [
                  createPermissionMenuItem(
                    permissionId: 'view_analytics',
                    title: 'System Analytics',
                    icon: Icons.analytics,
                    subtitle: 'View system performance',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showSystemAnalytics(context);
                    },
                  ),
                  createPermissionMenuItem(
                    permissionId: 'manage_users',
                    title: 'User Management',
                    icon: Icons.people,
                    subtitle: 'Manage user accounts',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showUserManagement(context);
                    },
                  ),
                ]),
                const Divider(),
                _buildDrawerSection(context, 'Debug Tools', [
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Colors.blue),
                    title: const Text('Camera Test'),
                    subtitle: const Text('Debug camera issues'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/camera-test');
                    },
                  ),
                ]),
              ],
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      accountName: Text(user?.displayName ?? 'User'),
      accountEmail: Text(user?.email ?? 'No email'),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          (user?.displayName?.substring(0, 1) ?? 'U').toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Text(
            'Secure App v1.0.0',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Role-based access control enabled',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showSystemAnalytics(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('System Analytics'),
            content: const Text('System analytics will be implemented here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showUserManagement(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Management'),
            content: const Text('User management will be implemented here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
