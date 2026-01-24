import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../utils/color_util.dart';
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
          child: Column(
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
                onTap: (_isSending || !_isButtonEnabled) ? () {} : () => _sendReset(),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isButtonEnabled ? ColorUtil.textColor : .new(0xFF1A343434),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  height: 48,
                  child: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                      : Center(
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReset() async {
    context.push('/verify');
    return;
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
      await _authService.forgotPassword(email: email, redirectUrl: redirectUrl);
      setState(() => _message = 'Reset link sent. Check your inbox.');
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      setState(() => _isSending = false);
    }
  }
}
