import 'package:dinq_app/constants/app_constants.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 弹出「Public Visibility」协议弹窗，返回 true 表示用户点了 Agree，
/// Cancel / 点击遮罩关闭返回 false。可 await，用于必须先同意才能继续的流程
/// （如 onboarding 发布 DINQ Card）。
Future<bool> showAgreementProtocolConfirm(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => const _AgreementProtocolDialog(),
  );
  return agreed == true;
}

/// 回调版（保留给 signin/signup 使用）：Agree 后执行 onContinue。
void showAgreementProtocolDialog(BuildContext context, {required VoidCallback onContinue}) {
  showAgreementProtocolConfirm(context).then((agreed) {
    if (agreed) onContinue();
  });
}

class _AgreementProtocolDialog extends StatelessWidget {
  const _AgreementProtocolDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Public Visibility",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Geist",
                color: ColorUtil.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "I agree that my DINQ Card will be publicly visible on the internet, appear in search engines, and be used in DINQ’s talent discovery features.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Geist",
                color: ColorUtil.textColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "By clicking Agree, you also agree to our ",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Geist",
                      color: Color(0xFF8E8E8E),
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: "Terms of Service",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push(
                          '/webview',
                          extra: {'url': termsUrl, 'navTitle': 'Terms of Service'},
                        );
                      },
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Geist",
                      color: ColorUtil.textColor,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.solid,
                    ),
                  ),
                  TextSpan(
                    text: " and ",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Geist",
                      color: Color(0xFF8E8E8E),
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: "Privacy Policy",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push(
                          '/webview',
                          extra: {'url': privacyUrl, 'navTitle': 'Privacy Policy'},
                        );
                      },
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Geist",
                      color: ColorUtil.textColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.solid,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: ".",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Geist",
                      color: Color(0xFF8E8E8E),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFD8D8D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Geist",
                        color: Color(0xFF636363),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtil.mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Agree",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Geist",
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
