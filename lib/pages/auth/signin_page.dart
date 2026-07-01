import 'package:dinq_app/utils/cache_manager.dart';
import 'package:dinq_app/utils/toast_util.dart';
import 'package:dinq_app/widgets/account/agreement_protocol_modal.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/common_dialog.dart';
import 'package:dinq_app/widgets/landing/invite_code_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:github_oauth_signin/github_oauth_signin.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

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
  late final GoogleSignIn _googleSignInClient = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isEnabled =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8;
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

    // dismissOnCapturedTaps: 用 Listener(onPointerUp) 收起键盘，不参与手势竞技场，
    // 避免裸 GestureDetector 抢走 TextField 的首次点击（首次激活弹不出键盘、需点两次）。
    return KeyboardDismissOnTap(
      dismissOnCapturedTaps: true,
      child: Scaffold(
        // 登录页不需要返回按钮，避免用户误返回到空白或历史页
        appBar: DefaultAppBar(context, isShowBack: false),
        resizeToAvoidBottomInset: false,
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
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              color: Color(0x66303030),
                              fontSize: 14,
                            ),
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
                            hintStyle: TextStyle(
                              color: Color(0x66303030),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: ColorUtil.textColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Row(
                          children: [
                            AssetImageView(
                              'signin_error_tip',
                              width: 24,
                              height: 24,
                            ),
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
                            : () => _handleSignIn(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isButtonEnabled
                                ? ColorUtil.textColor
                                : .new(0xFF1A343434),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Center(
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
                                  GoRouterState.of(context).extra
                                      as Map<String, dynamic>?;
                              final fromSignUp = extra?['fromSignUp'] == true;

                              if (fromSignUp) {
                                // 从注册页进入，返回注册页
                                context.pop();
                              } else {
                                // 从其他页面进入，跳转到注册页，并传递来源参数
                                context.push(
                                  '/signup',
                                  extra: {'fromSignIn': true},
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              color: Color(0xFFD8D8D8),
                              thickness: 0.5,
                            ),
                          ),
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
                          Expanded(
                            child: Divider(
                              color: Color(0xFFD8D8D8),
                              thickness: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      NormalButton(
                        onTap: () => _googleSignIn(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFECECEC),
                              width: 1,
                            ),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AssetImageView(
                                'google_icon',
                                width: 24,
                                height: 24,
                              ),
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
                        onTap: () {
                          _githubSignIn();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFECECEC),
                              width: 1,
                            ),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AssetImageView(
                                'github_icon',
                                width: 24,
                                height: 24,
                              ),
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
                    text: 'Login, you agree to our ',
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
                              extra: {
                                'url': '$appUrl/terms',
                                'navTitle': 'Terms of Service',
                              },
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
                              extra: {
                                'url': privacyUrl,
                                'navTitle': 'Privacy Policy',
                              },
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

  Future<void> _handleSignIn() async {
    setState(() => _error = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      // setState(() => _error = 'Please enter email and password.');
      await ToastUtil.show("Please enter email and password.");
      return;
    }

    try {
      await ToastUtil.showLoading();
      if (!mounted) return;
      await context.read<UserStore>().login(email: email, password: password);
      await ToastUtil.dismiss();
      if (!mounted) return;

      _handleLoginSuccess();
    } catch (error) {
      await ToastUtil.dismiss();
      ToastUtil.show("Username or password is incorrect.");
      // setState(() => _error = 'Username or password is incorrect.');
    }
  }

  Future<void> _googleSignIn() async {
    GoogleSignInAccount? googleSignInAccount = await _googleSignInClient
        .signIn();
    if (googleSignInAccount != null) {
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      // final avatar = googleSignInAccount.photoUrl ?? "";
      // final platformId = googleSignInAccount.id;
      // final name = googleSignInAccount.displayName ?? "";
      String platformAccessToken = googleSignInAuthentication.idToken ?? "";
      try {
        await ToastUtil.showLoading();
        if (!mounted) return;
        await context.read<UserStore>().thirdPartyLogin(
          provider: 'google',
          idToken: platformAccessToken,
        );
        await ToastUtil.dismiss();
        if (!mounted) return;

        _handleLoginSuccess();
      } catch (error) {
        await ToastUtil.dismiss();
        await ToastUtil.show("Login failed: $error");
      }
    }
  }

  Future<void> _githubSignIn() async {
    final GitHubSignIn gitHubSignIn = GitHubSignIn(
      clientId: 'Ov23livoAOOYkvlzKccK',
      clientSecret: '2cd66054c8c0659968925bcd9fec842636703bd6',
      redirectUrl: '$gatewayUrl/auth/oauth/github/callback',
    );

    final result = await gitHubSignIn.signIn(context);
    switch (result.status) {
      case GitHubSignInResultStatus.ok:
        if (result.userData != null) {
          final user = result.userData!;
        }

        try {
          await ToastUtil.showLoading();
          if (!mounted) return;
          await context.read<UserStore>().thirdPartyLogin(
            provider: 'github',
            idToken: result.token ?? '',
          );
          await ToastUtil.dismiss();
          if (!mounted) return;

          _handleLoginSuccess();
        } catch (error) {
          await ToastUtil.dismiss();
          await ToastUtil.show("Login failed: $error");
        }

        break;

      case GitHubSignInResultStatus.cancelled:
        break;

      case GitHubSignInResultStatus.failed:
        break;
    }
  }

  void _handleLoginSuccess({String? email}) async {
    // 先查询是否已经同意过协议
    final isAgree = await context.read<UserStore>().checkAgreement();
    if (!mounted) {
      return;
    }
    if (!isAgree) {
      showAgreementProtocolDialog(
        context,
        onContinue: () async {
          await context.read<UserStore>().agreeToTerms();
          _handleAgreementContinue(email: email);
        },
      );
    } else {
      _handleAgreementContinue(email: email);
    }
  }

  void _handleAgreementContinue({String? email}) {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    if (redirect != null && redirect.isNotEmpty) {
      context.go(redirect);
      if (email != null) {
        _showInviteCodeDialog(email);
      }
      return;
    }
    final flow = context.read<UserStore>().myFlow;
    if (flow != null && flow.status == 'success') {
      context.go('/admin/mydinq');
    } else {
      context.go('/');
    }
    if (email != null) {
      _showInviteCodeDialog(email);
    }
  }

  void _showInviteCodeDialog(String email) {
    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      // 注册后首次登录
      if (CacheManager.instance.signUpAccount != email) {
        CommonDialog.showAlert(
          context: context,
          customAlert: InviteCodeDialog(),
        );
        CacheManager.instance.signUpAccount = null;
      }
    });
  }
}
