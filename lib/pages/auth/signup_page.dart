import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/base_page.dart';

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
  bool _isButtonEnabled = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _codeController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isEnabled =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _codeController.text.trim().isNotEmpty;
    if (isEnabled != _isButtonEnabled && mounted) {
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _codeController.removeListener(_updateButtonState);
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

    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: DefaultAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Text(
                'Sign up',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Editor Note',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'name@example.com',
                    hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Verification code',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'Email verification code',
                    hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: NormalButton(
                      onTap: _isSendingCode ? () {} : _sendCode,
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.only(left: 12, right: 16, top: 13),
                        child: _isSendingCode
                            ? const SizedBox(height: 16, child: CircularProgressIndicator())
                            : Text(
                                'Send',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorUtil.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Invite code',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _inviteController,
                  decoration: InputDecoration(
                    hintText: 'Invite code (optional)',
                    hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Row(
                  children: [
                    AssetImageView('signin_error_tip', width: 24, height: 24),
                    const SizedBox(width: 4),
                    Text(
                      _error ?? 'Username or password is incorrect.',
                      style: TextStyle(
                        fontFamily: 'Tomato Grotesk',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFFC81E1D),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              NormalButton(
                onTap: (isLoading || !_isButtonEnabled) ? () {} : () => _handleSignUp(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isButtonEnabled ? ColorUtil.textColor : .new(0xFF1A343434),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  height: 48,
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                      : Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: _isButtonEnabled ? Colors.white : ColorUtil.sub2TextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              fontFamily: 'Tomato Grotesk',
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Have an account? ",
                    style: TextStyle(
                      color: ColorUtil.sub1TextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tomato Grotesk',
                    ),
                  ),
                  NormalButton(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: ColorUtil.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Tomato Grotesk',
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () {
                      // 获取路由参数，判断是否从登录页进入
                      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
                      final fromSignIn = extra?['fromSignIn'] == true;

                      if (fromSignIn) {
                        // 从登录页进入，返回登录页
                        context.pop();
                      } else {
                        // 从其他页面进入，跳转到登录页，并传递来源参数
                        context.push('/signin', extra: {'fromSignUp': true});
                      }
                    },
                  ),
                ],
              ),
            ],
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
