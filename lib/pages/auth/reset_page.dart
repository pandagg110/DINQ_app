import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../utils/color_util.dart';
import '../../utils/toast_util.dart';
import '../../widgets/common/base_page.dart';

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
  bool _isButtonEnabled = false;
  bool _isSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isEnabled = _emailController.text.trim().isNotEmpty;
    if (isEnabled != _isButtonEnabled && mounted) {
      _message = null;
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateButtonState);
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: DefaultAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isSent
              ? _buildSentView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 40,
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
                            text:
                                "Enter your email address and we'll send you a link to reset your password.",
                            style: TextStyle(fontSize: 14, color: ColorUtil.sub1TextColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    TextField(
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
                    const SizedBox(height: 12),
                    if (_message != null)
                      Row(
                        children: [
                          AssetImageView('signin_error_tip', width: 24, height: 24),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _message ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Tomato Grotesk',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFFC81E1D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 15),
                    NormalButton(
                      onTap: (_isSending || !_isButtonEnabled) ? () {} : () => _sendEmailCode(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isButtonEnabled ? ColorUtil.textColor : .new(0xFF1A343434),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        height: 48,
                        child: Center(
                          child: Text(
                            'Send Reset Email',
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
                          "Remember your password?",
                          style: TextStyle(
                            color: ColorUtil.sub1TextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Tomato Grotesk',
                          ),
                        ),
                        NormalButton(
                          child: Text(
                            ' Sign In',
                            style: TextStyle(
                              color: ColorUtil.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tomato Grotesk',
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
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

  Widget _buildSentView() {
    return Column(
      children: [
        const SizedBox(height: 42),
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: Color(0xFFDDFEBC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: AssetImageView('reset_send_success_icon', width: 32, height: 32)),
        ),
        const SizedBox(height: 16),
        Text(
          'Check your email',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ColorUtil.textColor,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "We've sent a password reset link to",
          style: TextStyle(fontSize: 14, color: ColorUtil.sub1TextColor, fontFamily: 'Geist'),
        ),
        Text(
          _emailController.text.trim(),
          style: TextStyle(
            fontSize: 14,
            color: ColorUtil.textColor,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Didn't receive the email? \nCheck your spam folder or try again.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 2,
            color: ColorUtil.sub1TextColor,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 20),
        NormalButton(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: ColorUtil.textColor,
              borderRadius: BorderRadius.circular(8),
            ),
            width: double.infinity,
            height: 48,
            child: Center(
              child: Text(
                'Back to Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Tomato Grotesk',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendEmailCode() async {
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
      await ToastUtil.showLoading();
      await _authService.forgotPassword(email: email, redirectUrl: redirectUrl);
      if (mounted) {
        setState(() {
          _isSent = true;
        });
      }
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      await ToastUtil.dismiss();
      setState(() => _isSending = false);
    }
  }
}
