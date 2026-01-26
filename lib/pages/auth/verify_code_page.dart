import 'package:dinq_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/loading_toast_util.dart';
import '../../utils/timer_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/default_app_bar.dart';
import 'verify_code_input.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final String password;

  const VerifyCodePage({super.key, required this.email, required this.password});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  late final VerificationCodeInputController _codeInputController =
      VerificationCodeInputController();
  bool _isFormValid = false;

  final _maxMillis = 60 * 1000;

  late final TimerUtil _timer = TimerUtil(mTotalTime: _maxMillis);

  late int _millisUntilFinished = _maxMillis;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _timer.setOnTimerTickCallback((millisUntilFinished) {
      if (mounted) {
        setState(() {
          _millisUntilFinished = millisUntilFinished;
        });
      }
    });
    _timer.startCountDown();
  }

  @override
  void dispose() {
    _codeInputController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: DefaultAppBar(context),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Text(
                'Check your email for a code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Editor Note',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "We've emailed a code to ",
                      style: TextStyle(fontSize: 14, color: ColorUtil.sub1TextColor),
                    ),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorUtil.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Not in your inbox? Check promotions or spam, and move it to your main inbox to receive future notifications.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Tomato Grotesk',
                  height: 1.6,
                  color: ColorUtil.sub1TextColor,
                ),
              ),
              const SizedBox(height: 30),
              VerificationCodeInput(
                controller: _codeInputController,
                maxLength: 6,
                valueChanged: (code) {
                  if (mounted) {
                    setState(() {
                      _isFormValid = code.length == 6;
                      // if (_isFormValid) {
                      //   _handleVerify(context);
                      // }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              NormalButton(
                onTap: () => _handleVerify(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isFormValid ? ColorUtil.textColor : Color(0x1A343434),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  height: 48,
                  child: Center(
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        color: _isFormValid ? Colors.white : ColorUtil.sub2TextColor,
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
                    "Didn't get the email? ",
                    style: TextStyle(
                      color: ColorUtil.sub1TextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tomato Grotesk',
                    ),
                  ),
                  NormalButton(
                    child: Text(
                      'Resend code ${((_millisUntilFinished > 0) ? " (${(_millisUntilFinished / 1000).toInt()}s)" : "")}',
                      style: TextStyle(
                        color: _millisUntilFinished > 0
                            ? ColorUtil.sub1TextColor
                            : ColorUtil.textColor,
                        fontSize: 14,
                        fontWeight: _millisUntilFinished > 0 ? FontWeight.w400 : FontWeight.w500,
                        fontFamily: 'Tomato Grotesk',
                        decoration: _millisUntilFinished > 0
                            ? TextDecoration.none
                            : TextDecoration.underline,
                      ),
                    ),
                    onTap: () {
                      _resendCode();
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

  /// 发送邮箱验证码
  Future<void> _resendCode() async {
    final email = widget.email;
    try {
      await LoadingToastUtil.showLoading();
      await _authService.sendCode(email: email, type: 'register');

      _millisUntilFinished = _maxMillis;
      _timer.mTotalTime = _maxMillis;
      _timer.startCountDown();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint('error9999: $error, $email');
    } finally {
      await LoadingToastUtil.dismiss();
      // setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleVerify(BuildContext context) async {
    context.go('/generation');
    return;
    if (!_isFormValid) return;
    _codeInputController.focusNode.unfocus();
    final code = _codeInputController.code;
    try {
      await context.read<UserStore>().register(
        email: widget.email,
        password: widget.password,
        verificationCode: code,
      );
      if (!mounted) return;
      context.go('/generation');
    } catch (error) {
      ToastUtil.showError(context: context, title: error.toString(), description: "");
    }
  }
}
