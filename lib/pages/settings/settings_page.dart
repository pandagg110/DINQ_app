import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/layout/app_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _SettingsTile(label: 'Profile', path: '/settings/profile'),
                _SettingsTile(label: 'Account', path: '/settings/account'),
                _SettingsTile(label: 'Verification', path: '/settings/verification'),
                _SettingsTile(label: 'DINQ Card', path: '/settings/dinqcard'),
                _SettingsTile(label: 'Subscription', path: '/settings/subscription'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(path),
    );
  }
}

