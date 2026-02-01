import 'package:dinq_app/utils/toast_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/common_dialog.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../utils/color_util.dart';

class SettingsSetPasswordPage extends StatefulWidget {
  final bool hasPassword;
  final VoidCallback? onSuccess;

  const SettingsSetPasswordPage({super.key, required this.hasPassword, this.onSuccess});

  @override
  State<SettingsSetPasswordPage> createState() => _SettingsSetPasswordPageState();
}

class _SettingsSetPasswordPageState extends State<SettingsSetPasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;

      // 验证当前密码（如果已设置密码）
      if (widget.hasPassword && _currentPasswordController.text.isEmpty) {
        _currentPasswordError = 'Please enter your current password';
        isValid = false;
      }

      // 验证新密码
      if (_newPasswordController.text.isEmpty) {
        _newPasswordError = 'Please enter a new password';
        isValid = false;
      } else if (_newPasswordController.text.length < 8) {
        _newPasswordError = 'Password must be at least 8 characters';
        isValid = false;
      }

      // 验证确认密码
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = 'Please confirm your new password';
        isValid = false;
      } else if (_confirmPasswordController.text != _newPasswordController.text) {
        _confirmPasswordError = 'Passwords do not match';
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.changePassword(
        currentPassword: widget.hasPassword ? _currentPasswordController.text : null,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;

      // 显示成功提示
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ToastUtil.show(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    final child = Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFDDFEBC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: AssetImageView("settings_success", width: 32, height: 32)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Password set successfully',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Geist'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  CommonDialog.closeDialog(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtil.textColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ok', style: TextStyle(fontFamily: 'Geist')),
              ),
            ),
          ],
        ),
      ),
    );
    CommonDialog.showAlert(context: context, customAlert: child);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: DefaultAppBar(context, titleString: 'Password'),
        body: Column(
          children: [
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Password (only show if has password)
                    if (widget.hasPassword) ...[
                      _buildLabel('Current Password'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        hint: 'Enter current password',
                        showPassword: _showCurrentPassword,
                        onToggleVisibility: () {
                          setState(() => _showCurrentPassword = !_showCurrentPassword);
                        },
                        errorText: _currentPasswordError,
                      ),
                      const SizedBox(height: 20),
                    ],
                    // New Password
                    _buildLabel('New Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      hint: 'Enter new password',
                      showPassword: _showNewPassword,
                      onToggleVisibility: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                      errorText: _newPasswordError,
                    ),
                    const SizedBox(height: 20),
                    // Confirm New Password
                    _buildLabel('Confirm New Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm new password',
                      showPassword: _showConfirmPassword,
                      onToggleVisibility: () {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
                      },
                      errorText: _confirmPasswordError,
                    ),
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
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ColorUtil.textColor),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            obscureText: !showPassword,
            style: TextStyle(fontSize: 14, color: ColorUtil.textColor, fontFamily: 'Geist'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: InputBorder.none,
              suffixIcon: NormalButton(
                onTap: onToggleVisibility,
                padding: EdgeInsets.only(top: 12, bottom: 12),
                child: AssetImageView(
                  showPassword ? 'password_show' : 'password_hide',
                  width: 24,
                  height: 24,
                ),
              ),
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
                errorText,
                style: const TextStyle(fontSize: 12, color: Colors.red, fontFamily: 'Geist'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
