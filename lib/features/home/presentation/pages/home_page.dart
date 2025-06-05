import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../services/rbac/role_manager.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated && state.user != null) {
          return _buildAuthenticatedHome(context, state.user!);
        }
        return _buildUnauthenticatedHome(context);
      },
    );
  }

  Widget _buildAuthenticatedHome(BuildContext context, User user) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Hero Section
              SliverToBoxAdapter(child: _buildHeroSection(context, user)),

              // Quick Stats
              if (user.isAdmin || user.isEditor)
                SliverToBoxAdapter(child: _buildQuickStats(context)),

              // Features Grid
              SliverPadding(
                padding: AppSpacing.screenPadding,
                sliver: SliverToBoxAdapter(
                  child: _buildFeaturesSection(context, user),
                ),
              ),

              // Quick Actions
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: _buildQuickActions(context, user),
                ),
              ),

              // Recent Activity
              SliverPadding(
                padding: AppSpacing.screenPadding,
                sliver: SliverToBoxAdapter(
                  child: _buildRecentActivity(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, User user) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.safeDisplayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildUserAvatar(context, user),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getRoleIcon(user.role), color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  user.roleDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
        ),
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        child: Text(
          user.initials,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
            context,
            icon: Icons.hotel,
            label: 'Total Rooms',
            value: '24',
            color: Colors.blue,
          ),
          _buildStatCard(
            context,
            icon: Icons.people,
            label: 'Occupancy',
            value: '87%',
            color: Colors.green,
          ),
          _buildStatCard(
            context,
            icon: Icons.shopping_cart,
            label: 'Orders Today',
            value: '12',
            color: Colors.orange,
          ),
          _buildStatCard(
            context,
            icon: Icons.attach_money,
            label: 'Revenue',
            value: '฿8.5k',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is RoomManager?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.bedroom_parent,
              title: 'Room Management',
              description: 'Efficiently manage all rooms and occupancy',
              color: Colors.blue,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.shopping_bag,
              title: 'In-App Shopping',
              description: 'Order amenities and services directly',
              color: Colors.green,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.receipt_long,
              title: 'Order Tracking',
              description: 'Track all room orders in real-time',
              color: Colors.orange,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Role-Based Access',
              description: 'Admin, Editor & User roles supported',
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, User user) {
    final actions = _getQuickActionsForRole(user.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...actions.map((action) => _buildActionTile(context, action)),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, QuickAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(action.icon, color: action.color),
        ),
        title: Text(
          action.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(action.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go(action.route),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                icon: Icons.login,
                title: 'Login successful',
                subtitle: 'Just now',
                color: Colors.green,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                icon: Icons.shopping_cart,
                title: 'New order from Room 201',
                subtitle: '5 minutes ago',
                color: Colors.blue,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                icon: Icons.check_circle,
                title: 'Room 105 checked out',
                subtitle: '1 hour ago',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildUnauthenticatedHome(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please login to continue',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.editor:
        return Icons.edit;
      case UserRole.user:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
    }
  }

  List<QuickAction> _getQuickActionsForRole(UserRole role) {
    final commonActions = [
      QuickAction(
        icon: Icons.person,
        title: 'My Profile',
        subtitle: 'View and edit your profile',
        route: '/profile',
        color: Colors.blue,
      ),
      QuickAction(
        icon: Icons.security,
        title: 'Privacy & Security',
        subtitle: 'Manage your security settings',
        route: '/privacy-security',
        color: Colors.green,
      ),
    ];

    switch (role) {
      case UserRole.admin:
        return [
          QuickAction(
            icon: Icons.dashboard,
            title: 'Admin Dashboard',
            subtitle: 'Manage users and system',
            route: '/admin',
            color: Colors.purple,
          ),
          ...commonActions,
        ];
      case UserRole.editor:
        return [
          QuickAction(
            icon: Icons.edit_note,
            title: 'Manage Rooms',
            subtitle: 'Edit room details and availability',
            route: '/rooms',
            color: Colors.orange,
          ),
          ...commonActions,
        ];
      case UserRole.user:
      case UserRole.guest:
        return commonActions;
    }
  }
}

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}
