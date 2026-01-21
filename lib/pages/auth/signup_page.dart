import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../stores/user_store.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _inviteController = TextEditingController();
  bool _showPassword = false;
  bool _isSendingCode = false;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final isLoading = userStore.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Sign up'),
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
                  'Create your account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join DINQ to build your professional card.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Verification code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSendingCode ? null : _sendCode,
                      child: _isSendingCode
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
                          : const Text('Send code'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inviteController,
                  decoration: const InputDecoration(labelText: 'Invite code (optional)'),
                ),
                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _handleSignUp(context),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                      : const Text('Create account'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/signin'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email first.');
      return;
    }
    setState(() {
      _error = null;
      _isSendingCode = true;
    });
    try {
      await _authService.sendCode(email: email, type: 'register');
    } catch (error) {
      debugPrint('error9999: $error');
      debugPrint('error9999: $email');
      setState(() => _error = error.toString());
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleSignUp(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final code = _codeController.text.trim();
    if (email.isEmpty || password.isEmpty || code.isEmpty) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }
    setState(() => _error = null);
    try {
      await context.read<UserStore>().register(
            email: email,
            password: password,
            verificationCode: code,
            inviteCode: _inviteController.text.trim().isEmpty ? null : _inviteController.text.trim(),
          );
      if (!mounted) return;
      context.go('/generation');
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }
}

