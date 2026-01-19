import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/user_store.dart';

class SettingsSubscriptionPage extends StatelessWidget {
  const SettingsSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final subscription = userStore.subscription;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Subscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Plan: ${subscription?.plan ?? 'free'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Status: ${subscription?.status ?? 'inactive'}'),
            const SizedBox(height: 8),
            Text('Credits: ${subscription?.creditsBalance ?? 0}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/pricing'),
              child: const Text('Manage plan'),
            ),
          ],
        ),
      ),
    );
  }
}

