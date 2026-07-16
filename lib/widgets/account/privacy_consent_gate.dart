import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../stores/privacy_consent_store.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/toast_util.dart';

/// 全局 privacy consent 门卫（对齐 Web app/provider.tsx +
/// PublicVisibilityModal）：
///
/// - 登录 / 登录态恢复后触发 GET /user/privacy-consent/status；
/// - 任意接口返回 4012 时（PrivacyConsentStore 的拦截器标记 required）
///   或状态检查结果为未同意时，且用户已有 DINQ Page（与 Web 一致），
///   在所有页面/弹层之上弹「Public Visibility」同意弹窗；
/// - Agree → POST /user/privacy-consent/agree，成功后关闭，链接类卡片
///   上传等写操作即恢复；Cancel → 登出回登录页（与 Web logoutToSignin 一致）。
///
/// 挂载在 MaterialApp.builder 中（Navigator 之上），因此弹窗覆盖包括
/// bottom sheet / dialog 在内的所有路由内容；路由跳转通过传入的 [router]。
class PrivacyConsentGate extends StatefulWidget {
  const PrivacyConsentGate({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<PrivacyConsentGate> createState() => _PrivacyConsentGateState();
}

class _PrivacyConsentGateState extends State<PrivacyConsentGate> {
  bool _wasLoggedIn = false;

  /// 与 Web hasExistingDinqPage 一致：flow 已发布或 user_data.domain 非空。
  /// consent 是「DINQ Card 公开可见」协议，仅对已有 DINQ Page 的账号弹窗
  /// （无 Page 的账号由 onboarding 流程收集同意）。
  bool _hasDinqPage(UserStore userStore) {
    final flow = userStore.myFlow;
    if (flow != null && flow.status == 'success' && flow.domain.isNotEmpty) {
      return true;
    }
    return (userStore.user?.userData.domain.trim().isNotEmpty) ?? false;
  }

  void _handleLoginTransition(bool loggedIn, PrivacyConsentStore consent) {
    if (loggedIn == _wasLoggedIn) return;
    _wasLoggedIn = loggedIn;
    // build 期间不能触发 notifyListeners，推迟到本帧结束
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (loggedIn) {
        consent.syncStatus();
      } else {
        consent.reset();
      }
    });
  }

  Future<void> _handleAgree(PrivacyConsentStore consent) async {
    final ok = await consent.agree();
    if (!ok) {
      ToastUtil.show('Failed to record privacy consent. Please try again.');
    }
  }

  void _handleCancel(UserStore userStore, PrivacyConsentStore consent) {
    if (consent.isAgreeing) return;
    // 与 Web logoutToSignin 一致：不同意则退出登录回登录页
    userStore.logout(userInitiated: true);
    widget.router.go('/signin');
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final consent = context.watch<PrivacyConsentStore>();
    final loggedIn = userStore.isLoggedIn();
    _handleLoginTransition(loggedIn, consent);

    final show = loggedIn && consent.isRequired && _hasDinqPage(userStore);

    return Stack(
      children: [
        widget.child,
        if (show) Positioned.fill(child: _buildModal(userStore, consent)),
      ],
    );
  }

  Widget _buildModal(UserStore userStore, PrivacyConsentStore consent) {
    // 文案/结构与 Web PublicVisibilityModal 及 App onboarding 的
    // agreement_protocol_modal 保持一致。挂载点在 Navigator 之上，
    // 需自带 Material 祖先，避免文本按无 Material 样式渲染。
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Public Visibility',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Geist',
                    color: ColorUtil.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I agree that my DINQ Card will be publicly visible on the '
                  'internet, appear in search engines, and be used in DINQ’s '
                  'talent discovery features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Geist',
                    color: ColorUtil.textColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'By clicking Agree, you also agree to our ',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
                          color: Color(0xFF8E8E8E),
                          height: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            widget.router.push(
                              '/webview',
                              extra: {
                                'url': termsUrl,
                                'navTitle': 'Terms of Service',
                              },
                            );
                          },
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
                          color: ColorUtil.textColor,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.solid,
                        ),
                      ),
                      const TextSpan(
                        text: ' and ',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
                          color: Color(0xFF8E8E8E),
                          height: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            widget.router.push(
                              '/webview',
                              extra: {
                                'url': privacyUrl,
                                'navTitle': 'Privacy Policy',
                              },
                            );
                          },
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
                          color: ColorUtil.textColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.solid,
                          height: 1.5,
                        ),
                      ),
                      const TextSpan(
                        text: '.',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
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
                        onPressed: consent.isAgreeing
                            ? null
                            : () => _handleCancel(userStore, consent),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD8D8D8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Geist',
                            color: Color(0xFF636363),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: consent.isAgreeing
                            ? null
                            : () => _handleAgree(consent),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorUtil.mainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          consent.isAgreeing ? 'Submitting...' : 'Agree',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Geist',
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
        ),
      ),
    );
  }
}
