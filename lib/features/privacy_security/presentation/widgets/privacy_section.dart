import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/security_settings.dart';
import '../bloc/security_bloc.dart';
import '../bloc/security_event.dart';

class PrivacySection extends StatelessWidget {
  final SecuritySettings settings;

  const PrivacySection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final preferences = settings.privacyPreferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy', style: Theme.of(context).textTheme.headlineSmall),
        AppSpacing.verticalGapMd,
        Card(
          child: Column(
            children: [
              _buildPrivacyTile(
                context,
                title: 'Show Email Address',
                subtitle: 'Let others see your email',
                icon: Icons.email,
                value: preferences.showEmail,
                onChanged:
                    (value) => _updatePreference(
                      context,
                      preferences.copyWith(showEmail: value),
                    ),
              ),
              const Divider(height: 1),
              _buildPrivacyTile(
                context,
                title: 'Show Phone Number',
                subtitle: 'Let others see your phone',
                icon: Icons.phone,
                value: preferences.showPhone,
                onChanged:
                    (value) => _updatePreference(
                      context,
                      preferences.copyWith(showPhone: value),
                    ),
              ),
              const Divider(height: 1),
              _buildPrivacyTile(
                context,
                title: 'Public Profile',
                subtitle: 'Make your profile visible to everyone',
                icon: Icons.public,
                value: preferences.showProfile,
                onChanged:
                    (value) => _updatePreference(
                      context,
                      preferences.copyWith(showProfile: value),
                    ),
              ),
              const Divider(height: 1),
              _buildPrivacyTile(
                context,
                title: 'Analytics',
                subtitle: 'Help us improve by sharing usage data',
                icon: Icons.analytics,
                value: preferences.allowAnalytics,
                onChanged:
                    (value) => _updatePreference(
                      context,
                      preferences.copyWith(allowAnalytics: value),
                    ),
              ),
              const Divider(height: 1),
              _buildPrivacyTile(
                context,
                title: 'Marketing Emails',
                subtitle: 'Receive updates and promotions',
                icon: Icons.mail,
                value: preferences.allowMarketing,
                onChanged:
                    (value) => _updatePreference(
                      context,
                      preferences.copyWith(allowMarketing: value),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  void _updatePreference(BuildContext context, PrivacyPreferences preferences) {
    context.read<SecurityBloc>().add(
      UpdatePrivacyPreferencesEvent(preferences),
    );
  }
}
