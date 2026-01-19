import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../stores/user_store.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        title: const Text('Sign in'),
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
                  'Welcome back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your DINQ profile and tools.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
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
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _handleSignIn(context),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/reset'),
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _oauthSignIn('google'),
                  child: const Text('Continue with Google'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _oauthSignIn('github'),
                  child: const Text('Continue with GitHub'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    setState(() => _error = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }

    try {
      await context.read<UserStore>().login(email: email, password: password);
      if (!mounted) return;
      final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
      if (redirect != null && redirect.isNotEmpty) {
        context.go(redirect);
        return;
      }
      final flow = context.read<UserStore>().myFlow;
      if (flow != null && flow.status == 'success') {
        context.go('/admin/mydinq');
      } else {
        context.go('/');
      }
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _oauthSignIn(String provider) async {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final nextUrl = redirect ?? appUrl;
    final url = Uri.parse('$gatewayUrl/api/v1/auth/oauth/$provider?redirect_uri=${Uri.encodeComponent(nextUrl)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

