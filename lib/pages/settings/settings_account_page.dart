import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../stores/user_store.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _message;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final email = userStore.user?.user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Signed in as $email'),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Change password'),
            ),
            const SizedBox(height: 12),
            if (_message != null) Text(_message!, style: const TextStyle(color: Colors.redAccent)),
            const Divider(height: 32),
            OutlinedButton(
              onPressed: () async {
                await _authService.deleteAccount();
                userStore.logout();
                if (!mounted) return;
                context.go('/');
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    try {
      await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      setState(() => _message = 'Password updated.');
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }
}

