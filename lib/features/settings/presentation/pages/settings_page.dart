import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../theme/presentation/widgets/theme_selector.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.spacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: context.typography.h1),
          AppSpacing.verticalGapLg,

          // Theme Section
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              Card(
                child: Padding(
                  padding: context.spacing.cardPadding ?? EdgeInsets.zero,
                  child: const ThemeSelector(),
                ),
              ),
            ],
          ),

          AppSpacing.verticalGapLg,

          // Account Section
          _buildSection(
            context,
            title: 'Account',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your account information',
                onTap: () {
                  // Navigate to profile settings
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  // Navigate to privacy settings
                },
              ),
            ],
          ),

          AppSpacing.verticalGapLg,

          // Preferences Section
          _buildSection(
            context,
            title: 'Preferences',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Configure notification preferences',
                onTap: () {
                  // Navigate to notification settings
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {
                  // Navigate to language settings
                },
              ),
            ],
          ),

          AppSpacing.verticalGapLg,

          // About Section
          _buildSection(
            context,
            title: 'About',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
                onTap: null,
              ),
              _buildSettingTile(
                context,
                icon: Icons.description,
                title: 'Terms of Service',
                subtitle: 'Read our terms',
                onTap: () {
                  // Navigate to terms
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  // Navigate to privacy policy
                },
              ),
            ],
          ),

          AppSpacing.verticalGapXl,

          // Sign Out Button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.customColors.warning,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              onPressed: () {
                _showSignOutDialog(context);
              },
            ),
          ),

          AppSpacing.verticalGapXl,
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.typography.h5),
        AppSpacing.verticalGapSm,
        ...children,
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<AuthBloc>().add(SignOutEvent());
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.customColors.warning,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }
}
