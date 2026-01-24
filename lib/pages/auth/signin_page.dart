import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

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
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isEnabled =
        _emailController.text.trim().isNotEmpty && _passwordController.text.length >= 8;
    if (isEnabled != _isButtonEnabled && mounted) {
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final isLoading = userStore.isLoading;

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
                    children: [
                      const SizedBox(height: 18),
                      Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: ColorUtil.textColor,
                          fontFamily: 'Editor Note',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Intelligent Social Card of the AI Era',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xA3303030)),
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
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            NormalButton(
                              onTap: () => context.push('/reset'),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
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
                        onTap: (isLoading || !_isButtonEnabled)
                            ? () {}
                            : () => _handleSignIn(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isButtonEnabled ? ColorUtil.textColor : .new(0xFF1A343434),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : Center(
                                  child: Text(
                                    'Sign in',
                                    style: TextStyle(
                                      color: _isButtonEnabled
                                          ? Colors.white
                                          : ColorUtil.sub2TextColor,
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
                            "Don't have an account? ",
                            style: TextStyle(
                              color: ColorUtil.sub1TextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tomato Grotesk',
                            ),
                          ),
                          NormalButton(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: ColorUtil.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Tomato Grotesk',
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            onTap: () {
                              // 获取路由参数，判断是否从注册页进入
                              final extra =
                                  GoRouterState.of(context).extra as Map<String, dynamic>?;
                              final fromSignUp = extra?['fromSignUp'] == true;

                              if (fromSignUp) {
                                // 从注册页进入，返回注册页
                                context.pop();
                              } else {
                                // 从其他页面进入，跳转到注册页，并传递来源参数
                                context.push('/signup', extra: {'fromSignIn': true});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Divider(color: Color(0xFFD8D8D8), thickness: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: ColorUtil.sub2TextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Tomato Grotesk',
                                height: 1.2,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFD8D8D8), thickness: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      NormalButton(
                        onTap: () => _oauthSignIn('google'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFECECEC), width: 1),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AssetImageView('google_icon', width: 24, height: 24),
                              const SizedBox(width: 16),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ColorUtil.textColor,
                                  fontFamily: 'Tomato Grotesk',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      NormalButton(
                        onTap: () => _oauthSignIn('github'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFECECEC), width: 1),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AssetImageView('github_icon', width: 24, height: 24),
                              const SizedBox(width: 16),
                              Text(
                                'Continue with Github',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ColorUtil.textColor,
                                  fontFamily: 'Tomato Grotesk',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
                child: RichText(
                  text: TextSpan(
                    text: 'Login,you agree to our ',
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
                        recognizer: TapGestureRecognizer()..onTap = () {},
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
                        text: 'privacy_policy.',
                        style: TextStyle(
                          color: ColorUtil.textColor,
                          fontSize: 12,
                          fontFamily: 'Tomato Grotesk',
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
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
      setState(() => _error = 'Username or password is incorrect.');
    }
  }

  Future<void> _oauthSignIn(String provider) async {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final nextUrl = redirect ?? appUrl;
    final url = Uri.parse(
      '$gatewayUrl/api/v1/auth/oauth/$provider?redirect_uri=${Uri.encodeComponent(nextUrl)}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
