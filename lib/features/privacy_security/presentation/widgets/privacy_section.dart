import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/security_settings.dart';
import '../bloc/security_bloc.dart';
import '../bloc/security_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PrivacySection extends StatelessWidget {
  final SecuritySettings settings;

  const PrivacySection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final preferences = settings.privacyPreferences;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String emailDisplay = 'No Email';
        String phoneDisplay = 'No Phone';

        if (authState is Authenticated && authState.user != null) {
          final user = authState.user!;
          emailDisplay = user.email ?? 'No Email';
          phoneDisplay = user.phoneNumber ?? 'No Phone';
        }

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
                    subtitle: 'Current: $emailDisplay',
                    icon: Icons.email,
                    iconColor: Colors.blue,
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
                    subtitle: 'Current: $phoneDisplay',
                    icon: Icons.phone,
                    iconColor: Colors.green,
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
                    iconColor: Colors.orange,
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
                    iconColor: Colors.purple,
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
                    iconColor: Colors.red,
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
            AppSpacing.verticalGapMd,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'When privacy settings are off, your information will be partially hidden to other users.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivacyTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  void _updatePreference(BuildContext context, PrivacyPreferences preferences) {
    context.read<SecurityBloc>().add(
      UpdatePrivacyPreferencesEvent(preferences),
    );
  }
}
