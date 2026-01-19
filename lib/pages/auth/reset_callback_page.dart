import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class ResetCallbackPage extends StatefulWidget {
  const ResetCallbackPage({super.key});

  @override
  State<ResetCallbackPage> createState() => _ResetCallbackPageState();
}

class _ResetCallbackPageState extends State<ResetCallbackPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    if (_codeController.text.isEmpty && query['code'] != null) {
      _codeController.text = query['code']!;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/signin'),
        ),
        title: const Text('Set new password'),
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
                  'Create a new password',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Reset code'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'New password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                if (_message != null) Text(_message!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
                      : const Text('Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (code.isEmpty || password.isEmpty) {
      setState(() => _message = 'Please enter code and new password.');
      return;
    }
    setState(() {
      _message = null;
      _isLoading = true;
    });
    try {
      await _authService.confirmReset(code: code, password: password);
      setState(() => _message = 'Password updated. You can sign in now.');
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

