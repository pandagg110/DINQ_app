import 'package:dinq_app/utils/cache_manager.dart';
import 'package:dinq_app/utils/toast_util.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
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
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // bool _isSendingCode = false;
  String? _error;
  bool _isButtonEnabled = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isEnabled =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _confirmPasswordController.text.length >= 8;
    if (isEnabled != _isButtonEnabled && mounted) {
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _confirmPasswordController.removeListener(_updateButtonState);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final userStore = context.watch<UserStore>();
    // final isLoading = userStore.isLoading;

    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: DefaultAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
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
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'At least 8 characters',
                            hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _showConfirmPassword = !_showConfirmPassword),
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
                              _error ?? '',
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
                        onTap: () => _handleSignUp(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isButtonEnabled ? ColorUtil.textColor : .new(0xFF1A343434),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Center(
                            child: Text(
                              'Continue',
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
                              final extra =
                                  GoRouterState.of(context).extra as Map<String, dynamic>?;
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
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
                child: RichText(
                  text: TextSpan(
                    text: 'Signup, you agree to our ',
                    style: TextStyle(
                      color: ColorUtil.sub2TextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tomato Grotesk',
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: ColorUtil.textColor,
                          fontSize: 12,
                          fontFamily: 'Tomato Grotesk',
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push(
                              '/webview',
                              extra: {'url': '$appUrl/terms', 'navTitle': 'Terms of Service'},
                            );
                          },
                      ),
                      TextSpan(
                        text: ' and ',
                        style: TextStyle(
                          color: ColorUtil.sub2TextColor,
                          fontSize: 12,
                          fontFamily: 'Tomato Grotesk',
                        ),
                      ),
                      TextSpan(
                        text: 'Privacy Policy.',
                        style: TextStyle(
                          color: ColorUtil.textColor,
                          fontSize: 12,
                          fontFamily: 'Tomato Grotesk',
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push(
                              '/webview',
                              extra: {'url': '$appUrl/privacy', 'navTitle': 'Privacy Policy'},
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() => _error = null);
    // 发送邮箱验证码
    await _sendCode();
  }

  /// 发送邮箱验证码
  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await ToastUtil.showLoading();
      await _authService.sendCode(email: email, type: 'register');
      await ToastUtil.dismiss();
      CacheManager.instance.signUpAccount = email;
      // 进入验证码页面
      if (!mounted) return;
      context.push('/verify', extra: {'email': email, 'password': password});
    } catch (error) {
      debugPrint('error9999: $error, $email');
      await ToastUtil.dismiss();
      setState(() => _error = error.toString());
    } finally {
      // setState(() => _isSendingCode = false);
    }
  }
}
