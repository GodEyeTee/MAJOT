import 'package:flutter/material.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/security_settings.dart';

class LoginHistorySection extends StatelessWidget {
  final List<LoginHistory> loginHistory;

  const LoginHistorySection({super.key, required this.loginHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Login History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () {
                // Show full history
              },
              child: const Text('View All'),
            ),
          ],
        ),
        AppSpacing.verticalGapMd,
        Card(
          child:
              loginHistory.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No login history available')),
                  )
                  : Column(
                    children:
                        loginHistory
                            .take(3)
                            .map(
                              (login) => Column(
                                children: [
                                  _buildLoginItem(context, login: login),
                                  if (loginHistory.indexOf(login) <
                                      (loginHistory.length > 3
                                          ? 2
                                          : loginHistory.length - 1))
                                    const Divider(height: 1),
                                ],
                              ),
                            )
                            .toList(),
                  ),
        ),
      ],
    );
  }

  Widget _buildLoginItem(BuildContext context, {required LoginHistory login}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            login.isSuccessful ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          login.isSuccessful ? Icons.check : Icons.close,
          color: login.isSuccessful ? Colors.green : Colors.red,
        ),
      ),
      title: Text(login.device.isNotEmpty ? login.device : 'Unknown Device'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(login.location.isNotEmpty ? login.location : 'Unknown Location'),
          Text(
            _formatTime(login.timestamp),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
      trailing:
          !login.isSuccessful
              ? IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () {
                  _showBlockConfirmation(context, login);
                },
              )
              : null,
    );
  }

  void _showBlockConfirmation(BuildContext context, LoginHistory login) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Block Device'),
            content: Text('Block ${login.device} from accessing your account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Block'),
              ),
            ],
          ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
