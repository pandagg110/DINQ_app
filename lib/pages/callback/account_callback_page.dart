import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountCallbackPage extends StatelessWidget {
  const AccountCallbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final status = params['status'] ?? 'success';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status == 'success' ? Icons.check_circle : Icons.error, size: 64, color: status == 'success' ? Colors.green : Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              status == 'success' ? 'Account connected successfully' : 'Account connection failed',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/settings/account'),
              child: const Text('Back to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

