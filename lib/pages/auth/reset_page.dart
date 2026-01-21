import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isSending = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/signin'),
        ),
        title: const Text('Reset password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'We will send a reset link to your email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                if (_message != null) Text(_message!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendReset,
                  child: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
                      : const Text('Send reset link'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email.');
      return;
    }
    setState(() {
      _message = null;
      _isSending = true;
    });
    try {
      // 构建重置密码回调 URL
      final redirectUrl = '${appUrl}/reset-callback';
      await _authService.forgotPassword(
        email: email,
        redirectUrl: redirectUrl,
      );
      setState(() => _message = 'Reset link sent. Check your inbox.');
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      setState(() => _isSending = false);
    }
  }
}

