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
          child: SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text(
              'Use fingerprint or face ID to secure your account',
            ),
            value: settings.biometricEnabled,
            onChanged: (value) {
              context.read<SecurityBloc>().add(ToggleBiometricEvent(value));
            },
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor..withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fingerprint,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
