import 'dart:math' as math;

import 'package:dinq_app/constants/app_constants.dart';
import 'package:dinq_app/utils/api_error.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/confirm_dialog.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/profile_service.dart';
import '../../stores/user_store.dart';
import 'social_oauth_page.dart';

class SettingsVerificationPage extends StatefulWidget {
  const SettingsVerificationPage({super.key});

  @override
  State<SettingsVerificationPage> createState() => _SettingsVerificationPageState();
}

class _SettingsVerificationPageState extends State<SettingsVerificationPage> {
  final ProfileService _profileService = ProfileService();
  bool _isSocialBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStore>().loadVerifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final verification = userStore.verify ?? {};
    final subscription = userStore.subscription;
    final isPaidUser = subscription?.plan != null && subscription!.plan != 'free';

    // 获取各验证项状态
    final educationData = verification['education'] as Map<String, dynamic>? ?? {};
    final careerData = verification['career'] as Map<String, dynamic>? ?? {};
    final socialData = verification['social'] as Map<String, dynamic>? ?? {};

    // 社交账号列表（对齐 Web：来自 verification overview 的 social.accounts）
    final linkedAccounts = (socialData['accounts'] as List<dynamic>?) ?? const [];

    final linkedinAccount = _findSocialAccount(linkedAccounts, 'linkedin');
    final twitterAccount = _findSocialAccount(linkedAccounts, 'twitter');

    final isLinkedinLinked = linkedinAccount?['linked'] == true;
    final isTwitterLinked = twitterAccount?['linked'] == true;

    // 是否有任何验证通过（用于显示虚线边框）
    final hasAnyVerified =
        (educationData['verified'] == true) ||
        (careerData['verified'] == true) ||
        (socialData['verified'] == true) ||
        isLinkedinLinked ||
        isTwitterLinked;

    return Scaffold(
      appBar: DefaultAppBar(context, titleString: "Verification", backgroundColor: Colors.white),
      backgroundColor: ColorUtil.pageBgColor,
      body: Column(
        children: [
          Expanded(
            child: _buildVerificationArea(
              hasAnyVerified: hasAnyVerified,
              educationData: educationData,
              careerData: careerData,
              socialData: socialData,
              isLinkedinLinked: isLinkedinLinked,
              isTwitterLinked: isTwitterLinked,
              isPaidUser: isPaidUser,
            ),
          ),
          // Upgrade 按钮（仅免费用户显示）
          if (!isPaidUser)
            Padding(
              padding: EdgeInsetsGeometry.only(
                left: 20,
                right: 20,
                bottom: math.max(24, MediaQuery.of(context).padding.bottom),
              ),
              child: _buildUpgradeButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationArea({
    required bool hasAnyVerified,
    required Map<String, dynamic> educationData,
    required Map<String, dynamic> careerData,
    required Map<String, dynamic> socialData,
    required bool isLinkedinLinked,
    required bool isTwitterLinked,
    required bool isPaidUser,
  }) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部提示卡片
                _buildTipCard(),
                const SizedBox(height: 8),
                // 验证项目列表
                Opacity(
                  opacity: isPaidUser ? 1.0 : 0.5,
                  child: _buildVerificationList(
                    educationData: educationData,
                    careerData: careerData,
                    socialData: socialData,
                    isLinkedinLinked: isLinkedinLinked,
                    isTwitterLinked: isTwitterLinked,
                    isPaidUser: isPaidUser,
                  ),
                ),
              ],
            ),
          ),
        ),
        Spacer(),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      margin: EdgeInsets.only(top: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2BE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFFDE277), width: 1),
      ),
      child: Text(
        "Get Verified – Unlock More Opportunities. Whether you're a job seeker or recruiter, completing verification instantly boosts your credibility",
        style: TextStyle(
          fontSize: 14,
          color: ColorUtil.textColor,
          fontFamily: 'Geist',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildVerificationList({
    required Map<String, dynamic> educationData,
    required Map<String, dynamic> careerData,
    required Map<String, dynamic> socialData,
    required bool isLinkedinLinked,
    required bool isTwitterLinked,
    required bool isPaidUser,
  }) {
    return Column(
      children: [
        // Education Verification
        _buildVerificationItem(
          iconPath: 'icon_edu',
          title: 'Education Verification',
          status: _getVerificationStatus(educationData),
          rejectionReason: educationData['rejection_reason']?.toString(),
          onTap: () => _handleVerificationTap('education', educationData, isPaidUser),
        ),
        _buildDivider(),
        // Career Verification
        _buildVerificationItem(
          iconPath: 'icon_career',
          title: 'Career Verification',
          status: _getVerificationStatus(careerData),
          rejectionReason: careerData['rejection_reason']?.toString(),
          onTap: () => _handleVerificationTap('career', careerData, isPaidUser),
        ),
        _buildDivider(),
        // Social Verification
        _buildVerificationItem(
          iconPath: 'icon_link',
          title: 'Social Verification',
          status: _getVerificationStatus(socialData),
          rejectionReason: socialData['rejection_reason']?.toString(),
          showStatus: false,
          onTap: () {},
        ),
        _buildSocialVerificationView(
          isLinkedinLinked: isLinkedinLinked,
          isTwitterLinked: isTwitterLinked,
          isPaidUser: isPaidUser,
        ),
      ],
    );
  }

  Map<String, dynamic>? _findSocialAccount(List<dynamic> accounts, String platform) {
    for (final raw in accounts) {
      if (raw is! Map) continue;
      final p = raw['platform']?.toString().toLowerCase() ?? '';
      if (platform == 'twitter') {
        if (p == 'twitter' || p == 'x') {
          return Map<String, dynamic>.from(raw);
        }
      } else if (p == platform) {
        return Map<String, dynamic>.from(raw);
      }
    }
    return null;
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }

  Widget _buildVerificationItem({
    required String iconPath,
    required String title,
    required VerificationStatus status,
    String? rejectionReason,
    bool showStatus = true,
    required VoidCallback onTap,
  }) {
    return NormalButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ColorUtil.textColor),
              ),
              child: Center(child: AssetImageView(iconPath, width: 24, height: 24)),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                  _buildStatusWidget(status, rejectionReason),
                ],
              ),
            ),
            // Status or Button
            if (showStatus && status == VerificationStatus.none) _buildLinkButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge({EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 4, right: 8),
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFDDFEBC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AssetImageView("settings_success", width: 16, height: 16),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(VerificationStatus status, String? rejectionReason) {
    switch (status) {
      case VerificationStatus.verified:
        return _buildVerifiedBadge(margin: const EdgeInsets.only(top: 4));
      case VerificationStatus.rejected:
        return _buildRejectedStatus(rejectionReason);
      case VerificationStatus.pending:
        return Container(
          height: 24,
          padding: const EdgeInsets.only(left: 8, right: 8),
          margin: EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFD97706),
              fontFamily: 'Geist',
            ),
          ),
        );
      case VerificationStatus.none:
        return SizedBox.shrink();
    }
  }

  Widget _buildRejectedStatus(String? rejectionReason) {
    return NormalButton(
      onTap: () {
        if (rejectionReason != null && rejectionReason.isNotEmpty) {
          _showRejectionReasonTooltip(rejectionReason);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 24,
              padding: const EdgeInsets.only(left: 4, right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFED7D7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssetImageView("icon_circle_close", width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Rejected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(width: 8),
              AssetImageView("icon_circle_error", width: 20, height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _showRejectionReasonTooltip(String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reason.isNotEmpty
                  ? reason
                  : 'We regret to inform you that your application was not successful. Please review the information provided and make any necessary corrections before resubmitting.',
              style: TextStyle(
                fontSize: 14,
                color: ColorUtil.sub1TextColor,
                fontFamily: 'Geist',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialVerificationView({
    required bool isLinkedinLinked,
    required bool isTwitterLinked,
    required bool isPaidUser,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border.all(color: Color(0xFFEFEFEF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildSocialRow(
            iconPath: 'icon_linkedin',
            label: 'Linkedin',
            platform: 'linkedin',
            displayName: 'LinkedIn',
            isLinked: isLinkedinLinked,
            isPaidUser: isPaidUser,
          ),
          const SizedBox(height: 16),
          _buildSocialRow(
            iconPath: 'icon_x',
            label: 'X',
            platform: 'twitter',
            displayName: 'X',
            isLinked: isTwitterLinked,
            isPaidUser: isPaidUser,
          ),
        ],
      ),
    );
  }

  /// 单个社交平台行：左侧图标 + 名称，右侧已绑定显示 Verified 徽标 + Unlink，
  /// 未绑定显示 Link（对齐 Web VerificationCard 的社交列表）。
  Widget _buildSocialRow({
    required String iconPath,
    required String label,
    required String platform,
    required String displayName,
    required bool isLinked,
    required bool isPaidUser,
  }) {
    return Row(
      children: [
        AssetImageView(iconPath, width: 24, height: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: ColorUtil.textColor,
              fontWeight: FontWeight.w500,
              fontFamily: "Geist",
            ),
          ),
        ),
        if (isLinked) ...[
          _buildVerifiedBadge(),
          const SizedBox(width: 8),
        ],
        NormalButton(
          onTap: () => _handleSocialLink(
            platform: platform,
            displayName: displayName,
            isLinked: isLinked,
            isPaidUser: isPaidUser,
          ),
          child: isLinked ? _buildUnlinkButton() : _buildLinkButton(),
        ),
      ],
    );
  }

  Widget _buildLinkButton() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorUtil.textColor),
      ),
      child: Center(
        child: Text(
          'Link',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorUtil.textColor,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }

  Widget _buildUnlinkButton() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: const Center(
        child: Text(
          'Unlink',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFEF4444),
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return NormalButton(
      onTap: () => context.push('/pricing'),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: ColorUtil.textColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Upgrade to Unlock',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }

  VerificationStatus _getVerificationStatus(Map<String, dynamic> data) {
    if (data.isEmpty) return VerificationStatus.none;

    final status = data['status']?.toString().toLowerCase();
    final verified = data['verified'] == true;

    if (verified || status == 'approved') {
      return VerificationStatus.verified;
    } else if (status == 'rejected') {
      return VerificationStatus.rejected;
    } else if (status == 'pending') {
      return VerificationStatus.pending;
    }
    return VerificationStatus.none;
  }

  void _handleVerificationTap(String type, Map<String, dynamic> data, bool isPaidUser) {
    if (!isPaidUser) {
      return;
    }

    // 跳转到对应的验证详情/提交页面
    if (type == 'education') {
      context.push('/settings/verification/education');
    } else if (type == 'career') {
      context.push('/settings/verification/career');
    } else if (type == 'social') {
      // Social verification 不需要单独页面
    }
  }

  Future<void> _handleSocialLink({
    required String platform,
    required String displayName,
    required bool isLinked,
    required bool isPaidUser,
  }) async {
    if (!isPaidUser || _isSocialBusy) return;

    if (isLinked) {
      await _unlinkSocialAccount(platform: platform, displayName: displayName);
      return;
    }

    await _linkSocialAccount(platform: platform, displayName: displayName);
  }

  Future<void> _unlinkSocialAccount({
    required String platform,
    required String displayName,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Unlink $displayName',
      content: 'Are you sure you want to unlink your $displayName account?',
      okText: 'Unlink',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSocialBusy = true);
    final userStore = context.read<UserStore>();
    try {
      await _profileService.unlinkSocialAccount({'platform': platform});
      await userStore.loadVerifications();
      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: '$displayName unlinked',
      );
    } catch (e) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Failed to unlink $displayName',
        description: apiErrorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _isSocialBusy = false);
    }
  }

  Future<void> _linkSocialAccount({
    required String platform,
    required String displayName,
  }) async {
    setState(() => _isSocialBusy = true);
    final userStore = context.read<UserStore>();
    try {
      final res = await _profileService.getSocialOAuthURL({'platform': platform});
      final authUrl = res['url']?.toString();
      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('Missing OAuth URL');
      }
      if (!mounted) return;

      final result = await Navigator.of(context).push<SocialOAuthResult>(
        MaterialPageRoute(
          builder: (_) => SocialOAuthPage(
            authUrl: authUrl,
            title: 'Link $displayName',
          ),
        ),
      );

      // 用户点返回关闭 WebView
      if (result == null || !mounted) return;

      if (!result.isSuccess) {
        final msg = result.errorDescription ??
            result.error ??
            'Authorization was cancelled or failed';
        TopToastUtil.showError(
          context: context,
          title: 'Failed to link $displayName',
          description: msg,
        );
        return;
      }

      await _profileService.linkSocialAccount({
        'platform': platform,
        'authorization_code': result.code,
        'redirect_uri': socialCallbackRedirectUri,
        'state': result.state,
      });
      await userStore.loadVerifications();
      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: '$displayName linked',
      );
    } catch (e) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Failed to link $displayName',
        description: apiErrorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _isSocialBusy = false);
    }
  }
}

enum VerificationStatus { none, pending, verified, rejected }
