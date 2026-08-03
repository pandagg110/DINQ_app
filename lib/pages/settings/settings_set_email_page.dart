import 'dart:async';

import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/color_util.dart';

class SettingsSetEmailPage extends StatefulWidget {
  final String? currentEmail;
  final VoidCallback? onSuccess;

  const SettingsSetEmailPage({super.key, this.currentEmail, this.onSuccess});

  @override
  State<SettingsSetEmailPage> createState() => _SettingsSetEmailPageState();
}

class _SettingsSetEmailPageState extends State<SettingsSetEmailPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  Timer? _timer;
  String? _emailError;
  String? _codeError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter email address');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _emailError = null;
      _isSendingCode = true;
    });

    try {
      await _authService.sendBindEmailCode(newEmail: email);
      if (!mounted) return;

      // 开始倒计时
      setState(() {
        _countdown = 60;
        _isSendingCode = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() => _countdown--);
        } else {
          timer.cancel();
        }
      });
      TopToastUtil.showSuccess(
        context: context,
        title: 'The verification code has been sent',
        description: '',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingCode = false);
      TopToastUtil.showError(
        context: context,
        title: 'Failed to send code',
        description: bindEmailErrorMessage(e),
      );
    }
  }

  Future<void> _handleSubmit() async {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _codeError = null;

      final email = _emailController.text.trim();
      final code = _codeController.text.trim();

      if (email.isEmpty) {
        _emailError = 'Please enter email address';
        isValid = false;
      } else if (!_isValidEmail(email)) {
        _emailError = 'Please enter a valid email address';
        isValid = false;
      }

      if (code.isEmpty) {
        _codeError = 'Please enter verification code';
        isValid = false;
      }
    });

    if (!isValid) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.bindEmail(
        newEmail: _emailController.text.trim(),
        code: _codeController.text.trim(),
      );
      if (!mounted) return;

      Navigator.pop(context);
      widget.onSuccess?.call();
      TopToastUtil.showSuccess(
        context: context,
        title: 'Email bound successfully',
        description: '',
      );
    } catch (e) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Failed to bind email',
        description: bindEmailErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChange = widget.currentEmail != null;

    return Scaffold(
      appBar: DefaultAppBar(context, titleString: 'Email'),
      body: Column(
        children: [
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isChange) ...[
                    Text(
                      'Current Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.currentEmail!,
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorUtil.sub2TextColor,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // New Email
                  Text(
                    isChange ? 'New Email' : 'Email Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEmailField(),
                  const SizedBox(height: 12),
                  _buildCodeField(),
                ],
              ),
            ),
          ),
          // Submit Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtil.textColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ColorUtil.sub4TextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isChange ? 'Change Email' : 'Bind Email',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final hasError = _emailError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: hasError ? Border.all(color: Colors.red) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 14, color: ColorUtil.textColor, fontFamily: 'Geist'),
            decoration: InputDecoration(
              hintText: 'Enter email address',
              hintStyle: TextStyle(
                fontSize: 14,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                _emailError!,
                style: const TextStyle(fontSize: 12, color: Colors.red, fontFamily: 'Geist'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCodeField() {
    final hasError = _codeError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: hasError ? Border.all(color: Colors.red) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, color: ColorUtil.textColor, fontFamily: 'Geist'),
                  decoration: InputDecoration(
                    errorText: hasError ? '' : null,
                    hintText: 'Code',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: ColorUtil.sub2TextColor,
                      fontFamily: 'Geist',
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: NormalButton(
                onTap: () {
                  if (_countdown > 0 || _isSendingCode) {
                    return;
                  }
                  _sendCode();
                },
                child: Container(
                  width: 109,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFE5E5E5)),
                  ),
                  child: Center(
                    child: _isSendingCode
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(ColorUtil.textColor),
                            ),
                          )
                        : Text(
                            _countdown > 0 ? '${_countdown}s' : 'Send Code',
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorUtil.textColor,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Geist',
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                _codeError!,
                style: const TextStyle(fontSize: 12, color: Colors.red, fontFamily: 'Geist'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
