import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/security_settings.dart';
import '../bloc/security_bloc.dart';
import '../bloc/security_event.dart';

class SecuritySection extends StatelessWidget {
  final SecuritySettings settings;

  const SecuritySection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Security', style: Theme.of(context).textTheme.headlineSmall),
        AppSpacing.verticalGapMd,
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Add an extra layer of security'),
                value: settings.twoFactorEnabled,
                onChanged: (value) {
                  context.read<SecurityBloc>().add(ToggleTwoFactorEvent(value));
                },
                secondary: const Icon(Icons.security),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Use fingerprint or face ID'),
                value: settings.biometricEnabled,
                onChanged: (value) {
                  context.read<SecurityBloc>().add(ToggleBiometricEvent(value));
                },
                secondary: const Icon(Icons.fingerprint),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Change Password'),
                subtitle: Text(
                  settings.lastPasswordChange != null
                      ? 'Last changed ${_formatDate(settings.lastPasswordChange!)}'
                      : 'Never changed',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 30) return '$difference days ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    return '${(difference / 365).floor()} years ago';
  }

  void _showChangePasswordDialog(BuildContext context) {
    // Implementation
  }
}
