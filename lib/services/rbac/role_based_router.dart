import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'rbac_service.dart';

Widget buildWithPermissionCheck({
  required BuildContext context,
  required GoRouterState state,
  required Widget Function(BuildContext, GoRouterState) builder,
  required List<String> requiredPermissions,
  Widget Function(BuildContext)? unauthorizedBuilder,
}) {
  final rbacService = RBACService();

  if (requiredPermissions.isEmpty ||
      rbacService.hasAnyPermission(requiredPermissions)) {
    return builder(context, state);
  } else {
    return unauthorizedBuilder?.call(context) ??
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('You don\'t have permission to access this page.'),
              ],
            ),
          ),
        );
  }
}
