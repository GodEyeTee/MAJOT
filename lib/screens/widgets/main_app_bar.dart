import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../services/rbac/role_manager.dart';
import '../main_screen.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final NavigationItem currentItem;
  final User? user;
  final VoidCallback onRefresh;
  final int visibleItemsCount;

  const MainAppBar({
    super.key,
    required this.currentItem,
    required this.user,
    required this.onRefresh,
    required this.visibleItemsCount,
  });

  @override
  Widget build(BuildContext context) {
    final role = user?.role.displayName ?? 'Unknown';

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentItem.label),
          Text(
            '$role • $visibleItemsCount features',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh User Data',
        ),
        _buildSecurityIndicator(),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text('Profile (${user?.email ?? 'Unknown'})'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Refresh Data',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'security',
                  child: Row(
                    children: [
                      Icon(Icons.security),
                      SizedBox(width: 8),
                      Text('Security Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildSecurityIndicator() {
    final securityLevel = _getSecurityLevel();
    Color indicatorColor;
    IconData indicatorIcon;

    switch (securityLevel) {
      case 'high':
        indicatorColor = Colors.green;
        indicatorIcon = Icons.security;
        break;
      case 'medium':
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.shield;
        break;
      default:
        indicatorColor = Colors.blue;
        indicatorIcon = Icons.verified_user;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Icon(indicatorIcon, color: indicatorColor, size: 20),
    );
  }

  String _getSecurityLevel() {
    if (user?.role == null) return 'unknown';
    switch (user!.role.name) {
      case 'admin':
        return 'high';
      case 'editor':
        return 'medium';
      default:
        return 'standard';
    }
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'profile':
        _showUserProfile(context);
        break;
      case 'refresh':
        onRefresh();
        break;
      case 'security':
        _showSecuritySettings(context);
        break;
      case 'signout':
        _showSignOutDialog(context);
        break;
    }
  }

  void _showUserProfile(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Email: ${user?.email ?? "No email"}'),
                Text('Role: ${user?.role.displayName ?? "No role"}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRefresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Security Settings'),
            content: const Text('Security settings will be implemented here.'),
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
