import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/security_bloc.dart';
import '../bloc/security_event.dart';
import '../bloc/security_state.dart';
import '../widgets/security_section.dart';
import '../widgets/privacy_section.dart';
import '../widgets/login_history_section.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  void _loadSecuritySettings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && authState.user != null) {
      context.read<SecurityBloc>().add(
        LoadSecuritySettingsEvent(authState.user!.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: BlocBuilder<SecurityBloc, SecurityState>(
        builder: (context, state) {
          if (state is SecurityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SecurityError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSecuritySettings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SecurityLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _loadSecuritySettings(),
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SecuritySection(settings: state.settings),
                    AppSpacing.verticalGapLg,
                    const Divider(),
                    AppSpacing.verticalGapLg,
                    PrivacySection(settings: state.settings),
                    AppSpacing.verticalGapLg,
                    const Divider(),
                    AppSpacing.verticalGapLg,
                    LoginHistorySection(
                      loginHistory: state.settings.loginHistory,
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
