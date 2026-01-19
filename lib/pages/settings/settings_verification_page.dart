import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/user_store.dart';

class SettingsVerificationPage extends StatelessWidget {
  const SettingsVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStore>();
    final verification = store.verify ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VerificationTile(
              label: 'Education',
              status: verification['education']?['status']?.toString() ?? 'Not submitted',
            ),
            _VerificationTile(
              label: 'Career',
              status: verification['career']?['status']?.toString() ?? 'Not submitted',
            ),
            _VerificationTile(
              label: 'Social',
              status: verification['social']?['status']?.toString() ?? 'Not submitted',
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(status),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

