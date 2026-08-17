import 'package:dinq_app/utils/api_error.dart';
import 'package:dinq_app/utils/cache_manager.dart';
import 'package:dinq_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/common_dialog.dart';
import 'package:dinq_app/widgets/landing/invite_code_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../services/apple_sign_in_service.dart';
import '../../services/auth_service.dart';
import '../../services/github_oauth.dart';
import '../../services/oauth_login_attempt.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/password_field_keyboard.dart';
import '../../utils/unfocus_on_tap_outside.dart';
import '../../widgets/common/default_app_bar.dart';
import 'github_oauth_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  /// 上一持焦输入框：用于判断邮箱↔密码（普通键盘↔安全键盘）互切。
  FocusNode? _lastFocusedField;

  /// 互切 hide→show 窗口期内，忽略 onTap 的立刻 show，避免抢跑。
  bool _suppressTapShow = false;
  bool _showPassword = false;
  String? _error;
  bool _isButtonEnabled = false;
  final _appleSignInGuard = OAuthLoginAttemptGuard();
  late final GoogleSignIn _googleSignInClient = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _emailFocusNode.addListener(() => _onFieldFocusChange(_emailFocusNode));
    _passwordFocusNode.addListener(
      () => _onFieldFocusChange(_passwordFocusNode),
    );
  }

  void _updateButtonState() {
    final isEnabled =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8;
    if (isEnabled != _isButtonEnabled && mounted) {
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  void _onFieldFocusChange(FocusNode node) {
    if (!node.hasFocus) {
      // 两框都失焦（点空白收起）时清空，避免下次误判为互切
      if (!_emailFocusNode.hasFocus && !_passwordFocusNode.hasFocus) {
        _lastFocusedField = null;
      }
      return;
    }
    final previous = _lastFocusedField;
    final switched = previous != null && !identical(previous, node);
    _lastFocusedField = node;
    if (switched) {
      // 邮箱(普通) ↔ 密码(安全) 互切：先 hide 再延后 show
      _suppressTapShow = true;
      scheduleImeSwitchSoftKeyboard(node);
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        _suppressTapShow = false;
      });
    } else {
      scheduleSoftKeyboardRetries(node);
    }
  }

  /// 已获焦再点：focus 不变，listener 不会触发，需补弹。
  void _onFieldTap(FocusNode node) {
    if (_suppressTapShow) return;
    ensureSoftKeyboardVisible(node);
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final isLoading = userStore.isLoading;
    return Scaffold(
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
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        onTapOutside: unfocusOnTapOutside,
                        onTap: () => _onFieldTap(_emailFocusNode),
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
                        focusNode: _passwordFocusNode,
                        obscureText: !_showPassword,
                        keyboardType: kPasswordKeyboardType,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        enableInteractiveSelection: true,
                        onTapOutside: unfocusOnTapOutside,
                        // 小米：安全键盘↔普通键盘互切由 focus listener 处理；已获焦再点由此补弹
                        onTap: () => _onFieldTap(_passwordFocusNode),
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
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
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
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.iOS) ...[
                      const SizedBox(height: 10),
                      NormalButton(
                        onTap: _appleSignIn,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFECECEC),
                              width: 1,
                            ),
                          ),
                          width: double.infinity,
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/apple_icon.svg',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Continue with Apple',
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
                              'url': termsUrl,
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

    await runLoginAttempt<void>(
      authenticate: () async {
        await ToastUtil.showLoading();
        if (!mounted) return;
        await context.read<UserStore>().login(email: email, password: password);
      },
      onAuthenticated: () async {
        try {
          await ToastUtil.dismiss();
        } catch (_) {}
        if (mounted) _handleLoginSuccess();
      },
      onAuthenticationFailed: (error) async {
        await ToastUtil.dismiss();
        // Only credential failures use the fixed copy; gateway errors retain
        // their useful diagnostic message.
        final status = error is DioException
            ? error.response?.statusCode
            : null;
        final isCredentialError = status == 401 || status == 400;
        await ToastUtil.show(
          isCredentialError
              ? 'Username or password is incorrect.'
              : apiErrorMessage(error),
        );
      },
    );
  }

  Future<void> _googleSignIn() async {
    await runOAuthLoginAttempt(
      authenticate: () async {
        final googleSignInAccount = await selectGoogleAccount(
          clearCachedAccount: () async {
            await _googleSignInClient.signOut();
          },
          signIn: _googleSignInClient.signIn,
        );
        if (googleSignInAccount == null) return false;

        final authentication = await googleSignInAccount.authentication;
        final idToken = requireGoogleIdToken(authentication.idToken);
        await ToastUtil.showLoading();
        if (!mounted) {
          await ToastUtil.dismiss();
          return false;
        }
        await context.read<UserStore>().thirdPartyLogin(
          provider: 'google',
          idToken: idToken,
        );
        return true;
      },
      onAuthenticated: () async {
        try {
          await ToastUtil.dismiss();
        } catch (_) {}
        if (mounted) _handleLoginSuccess();
      },
      onAuthenticationFailed: (error) async {
        await ToastUtil.dismiss();
        await ToastUtil.show(
          thirdPartyLoginErrorMessage(provider: 'google', error: error),
        );
      },
    );
  }

  Future<void> _githubSignIn() async {
    if (githubClientId.trim().isEmpty) {
      await ToastUtil.show('GitHub login is not configured.');
      return;
    }

    final redirectUri = Uri.tryParse(githubRedirectUrl);
    if (redirectUri == null) {
      await ToastUtil.show('GitHub login is not configured.');
      return;
    }
    try {
      GitHubOAuth.buildAuthorizationUri(
        clientId: githubClientId,
        redirectUri: redirectUri,
        state: 'configuration-check',
      );
    } on GitHubOAuthException catch (error) {
      await ToastUtil.show(error.message);
      return;
    }
    if (!mounted) return;

    final result = await Navigator.of(context).push<GitHubOAuthResult>(
      MaterialPageRoute(
        builder: (_) =>
            GitHubOAuthPage(clientId: githubClientId, redirectUri: redirectUri),
      ),
    );
    if (result == null) return;
    if (!result.isSuccess) {
      await ToastUtil.show(result.error ?? 'GitHub login failed.');
      return;
    }

    await runOAuthLoginAttempt(
      authenticate: () async {
        await ToastUtil.showLoading();
        if (!mounted) {
          await ToastUtil.dismiss();
          return false;
        }
        await context.read<UserStore>().thirdPartyLogin(
          provider: 'github',
          idToken: result.code!,
          redirectUri: githubRedirectUrl,
        );
        return true;
      },
      onAuthenticated: () async {
        try {
          await ToastUtil.dismiss();
        } catch (_) {}
        if (mounted) _handleLoginSuccess();
      },
      onAuthenticationFailed: (error) async {
        await ToastUtil.dismiss();
        await ToastUtil.show(
          thirdPartyLoginErrorMessage(provider: 'github', error: error),
        );
      },
    );
  }

  Future<void> _appleSignIn() async {
    await _appleSignInGuard.run(() async {
      await runOAuthLoginAttempt(
        authenticate: () async {
          final credential = await AppleSignInService.authorize();
          if (credential == null) return false;

          if (kDebugMode) {
            debugPrint(
              'Apple identity token: '
              '${AppleSignInService.inspectIdentityToken(credential.identityToken)}',
            );
          }

          await ToastUtil.showLoading();
          if (!mounted) {
            await ToastUtil.dismiss();
            return false;
          }
          await context.read<UserStore>().thirdPartyLogin(
            provider: 'apple',
            idToken: credential.identityToken,
            authorizationCode: credential.authorizationCode,
            nonce: credential.rawNonce,
            givenName: credential.givenName,
            familyName: credential.familyName,
          );
          return true;
        },
        onAuthenticated: () async {
          try {
            await ToastUtil.dismiss();
          } catch (_) {}
          if (mounted) _handleLoginSuccess();
        },
        onAuthenticationFailed: (error) async {
          await ToastUtil.dismiss();
          if (kDebugMode) {
            final statusCode = error is DioException
                ? error.response?.statusCode
                : null;
            debugPrint(
              'Apple login failed: type=${error.runtimeType}, '
              'status=$statusCode, '
              'message=${thirdPartyLoginErrorMessage(provider: 'apple', error: error)}',
            );
          }
          final message = error is AppleSignInException
              ? error.message
              : thirdPartyLoginErrorMessage(provider: 'apple', error: error);
          await ToastUtil.show(message);
        },
      );
    });
  }

  void _handleLoginSuccess({String? email}) {
    // 对齐 Web：登录后的 privacy consent 状态检查与「Public Visibility」
    // 弹窗由全局 PrivacyConsentGate 统一处理（登录态变化时自动
    // GET /user/privacy-consent/status，required 时在任意页面弹窗，
    // Agree 才写入服务端）。此前本页 Cancel/关闭弹窗后用户会带着
    // 未同意状态进入 App，导致后续 card/generate 全部 4012。
    _handleAgreementContinue(email: email);
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
    // 登录成功后默认进入 Search 页
    context.go('/search');
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
