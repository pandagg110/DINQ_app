import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/utils/toast_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class InviteCodeDialog extends StatefulWidget {
  const InviteCodeDialog({super.key});

  @override
  State<InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<InviteCodeDialog> {
  final _codeController = TextEditingController();

  final _authService = AuthService();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(25),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Color(0xFFFFEDBC), Color(0xFFFFFDF6)],
              begin: AlignmentGeometry.topCenter,
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Stack(
            children: [
              AssetImageView('invite_code_dialog_bg', width: 280, height: 140),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssetImageView('invite_code_gift', width: 120, height: 120),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        "Get EXTRA ",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "5 CREDITS",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6F15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter an invite code to instantly unlock your bonus',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Invite Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                          color: ColorUtil.textColor,
                        ),
                      ),
                      Text(
                        ' (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD8D8D8), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter invite code to claim your bonus',
                        hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Don't have an invite code? ",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  NormalButton(
                    onTap: () {
                      _clickClaimButton();
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
                          'Claim 5 Credits',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NormalButton(
                    child: SizedBox(
                      height: 32,
                      child: Center(
                        child: Text(
                          "Later",
                          style: TextStyle(fontSize: 14, color: Color(0x33303030)),
                        ),
                      ),
                    ),
                    onTap: () {
                      context.pop();
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

  Future<void> _clickClaimButton() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      return;
    }
    try {
      await ToastUtil.showLoading();
      _authService.activate(inviteCode: code);
      await ToastUtil.dismiss();
      ToastUtil.show("Congratulations! You've received 5 bonus Credits! 🎉");
    } catch (error) {
      debugPrint('error9999: $error');
      await ToastUtil.dismiss();
      ToastUtil.show(error.toString());
    }
  }
}
