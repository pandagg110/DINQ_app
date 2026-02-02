import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:dinq_app/widgets/common/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';

import '../common/base_page.dart';

/// 显示删除账户警告对话框（第一步）
void showDeleteAccountWarningDialog(BuildContext context, {required VoidCallback onContinue}) {
  showDialog(
    context: context,
    builder: (context) => _DeleteAccountWarningDialog(
      onContinue: () {
        Navigator.pop(context);
        onContinue();
      },
    ),
  );
}

/// 第一步：警告对话框
class _DeleteAccountWarningDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const _DeleteAccountWarningDialog({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24, color: ColorUtil.textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Color(0xFFEFEFEF)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  // Warning box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2BE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDCA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, size: 18, color: ColorUtil.textColor),
                            const SizedBox(width: 4),
                            Text(
                              'Warning',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ColorUtil.textColor,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'This action cannot be undone. Please make sure you want to proceed.',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorUtil.textColor,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    'Deleting your account will permanently remove all your data, including:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List items
                  _buildListItem('Your profile information'),
                  _buildListItem('All your posts and content'),
                  _buildListItem('Your connections and network'),
                  _buildListItem('Your verification status'),
                  _buildListItem('All associated data'),
                  const SizedBox(height: 20),
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE12C2C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'I Understand, Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ColorUtil.sub4TextColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ColorUtil.textColor,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: ColorUtil.sub2TextColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: ColorUtil.sub1TextColor, fontFamily: 'Geist'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 第二步：Delete Account 确认页面（全屏弹窗）
class DeleteAccountConfirmModal extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const DeleteAccountConfirmModal({super.key, required this.onConfirm});

  @override
  State<DeleteAccountConfirmModal> createState() => _DeleteAccountConfirmModalState();
}

class _DeleteAccountConfirmModalState extends State<DeleteAccountConfirmModal> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isDeleteEnabled {
    return _confirmController.text.trim().toUpperCase() == 'DELETE';
  }

  Future<void> _handleDelete() async {
    if (!_isDeleteEnabled) return;

    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      // 显示成功弹窗
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      TopToastUtil.showError(
        context: context,
        title: 'Failed to delete account',
        description: '$e',
      );
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
              'Account deleted successfully',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Geist'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  CommonDialog.closeDialog(context);
                  context.pop(true); // 传递 true 表示删除成功
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
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2BE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECDCA)),
                      ),
                      child: Text(
                        'Once you confirm, your account will be permanently deleted and cannot be recovered.',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorUtil.textColor,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Final confirmation title
                    Text(
                      'Final Confirmation Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Instruction text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorUtil.sub1TextColor,
                          fontFamily: 'Geist',
                        ),
                        children: [
                          const TextSpan(text: 'To confirm account deletion, please type '),
                          TextSpan(
                            text: '"DELETE"',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColorUtil.textColor,
                            ),
                          ),
                          const TextSpan(text: ' in the box below:'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Input field
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: ColorUtil.sub4TextColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _confirmController,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorUtil.textColor,
                          fontFamily: 'Geist',
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type DELETE to confirm',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: ColorUtil.sub2TextColor,
                            fontFamily: 'Geist',
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_isDeleting || !_isDeleteEnabled) ? null : _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE12C2C),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Delete Account Permanently',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Geist',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ColorUtil.sub4TextColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ColorUtil.textColor,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
