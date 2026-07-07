import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../stores/user_store.dart';
import '../../widgets/account/delete_account_modal.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  bool _isConnectingGithub = false;

  @override
  void initState() {
    super.initState();
    // 加载账号列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStore>().loadUserAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final user = userStore.user?.user;
    final hasPassword = user?.hasPassword ?? false;
    final connectedAccounts = userStore.connectedAccounts;

    // 查找各平台连接状态
    final emailAccount = connectedAccounts.firstWhere(
      (a) => a['provider'] == 'email',
      orElse: () => {'provider': 'email', 'connected': false},
    );
    final githubAccount = connectedAccounts.firstWhere(
      (a) => a['provider'] == 'github',
      orElse: () => {'provider': 'github', 'connected': false},
    );

    final isEmailConnected = emailAccount['connected'] == true;
    final isGithubConnected = githubAccount['connected'] == true;
    final emailAddress = emailAccount['email']?.toString() ?? '';

    return Scaffold(
      appBar: DefaultAppBar(context, titleString: "Accounts", backgroundColor: Colors.transparent),
      backgroundColor: ColorUtil.pageBgColor,
      body: Column(
        children: [
          // 主要设置区域
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Password
                _buildAccountItem(
                  imgName: 'settings_accounts_lock',
                  title: 'Password',
                  subtitle: hasPassword ? 'Password set' : 'Not set',
                  buttonText: hasPassword ? 'Change' : 'Set',
                  onTap: () => _pushChangePassword(hasPassword),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),
                // Email
                _buildAccountItem(
                  imgName: 'settings_accounts_mail',
                  title: 'Email',
                  subtitle: isEmailConnected ? emailAddress : 'Not set',
                  buttonText: isEmailConnected ? 'Change' : 'Bind',
                  onTap: () => _pushChangeEmail(isEmailConnected ? emailAddress : null),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: _buildGithubItem(
              isConnected: isGithubConnected,
              displayUrl: githubAccount['display_url']?.toString(),
              onConnect: () => _handleGithubConnect(),
              onDisconnect: () => _handleGithubDisconnect(
                hasPassword: hasPassword,
                isEmailConnected: isEmailConnected,
                connectedAccounts: connectedAccounts,
              ),
            ),
          ),
          // Delete Account
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: _buildDeleteAccountItem(),
          ),
          const Spacer(),
          // Log out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: _buildLogoutButton(userStore),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required String imgName,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              border: Border.all(color: Color(0x12303030), width: 1),
            ),
            child: Center(child: AssetImageView(imgName, width: 24, height: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Color(0xFF575757), fontFamily: 'Geist'),
                ),
              ],
            ),
          ),
          _buildOutlineButton(buttonText, onTap),
        ],
      ),
    );
  }

  Widget _buildGithubItem({
    required bool isConnected,
    String? displayUrl,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          AssetImageView('github_icon', width: 48, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Github',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? (displayUrl ?? 'Connected') : 'Not connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorUtil.sub2TextColor,
                    fontFamily: 'Geist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _isConnectingGithub
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _buildOutlineButton(
                  isConnected ? 'Disconnect' : 'Connect',
                  isConnected ? onDisconnect : onConnect,
                ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountItem() {
    return NormalButton(
      onTap: _showDeleteAccountModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            AssetImageView("gray_right", width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(UserStore userStore) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: NormalButton(
        onTap: () {
          userStore.logout();
          context.go('/');
        },
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(
              'Log out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorUtil.textColor,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onTap) {
    return NormalButton(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color(0xFFE6E6E6)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }

  void _pushChangePassword(bool hasPassword) {
    context.push('/settings/account/password', extra: {'hasPassword': hasPassword});
  }

  void _pushChangeEmail(String? currentEmail) {
    context.push('/settings/account/email', extra: {'currentEmail': currentEmail});
  }

  void _showDeleteAccountModal() {
    // 第一步：显示警告对话框
    showDeleteAccountWarningDialog(
      context,
      onContinue: () {
        // 第二步：显示确认页面
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => DeleteAccountConfirmModal(
            onConfirm: () async {
              await _authService.deleteAccount();
            },
          ),
        ).then((result) {
          // 如果删除成功，登出并跳转
          if (result == true) {
            context.read<UserStore>().logout();
            context.go('/');
          }
        });
      },
    );
  }

  Future<void> _handleGithubConnect() async {
    setState(() => _isConnectingGithub = true);
    try {
      final response = await _profileService.getAccountLinkOAuthURL(platform: 'github');
      final authUrl = response['auth_url']?.toString();
      if (authUrl != null && authUrl.isNotEmpty) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect GitHub: $e')));
    } finally {
      if (mounted) {
        setState(() => _isConnectingGithub = false);
      }
    }
  }

  Future<void> _handleGithubDisconnect({
    required bool hasPassword,
    required bool isEmailConnected,
    required List<dynamic> connectedAccounts,
  }) async {
    // 计算已连接的账号数量
    final connectedCount = connectedAccounts.where((a) => a['connected'] == true).length;

    // 至少保留一个连接的账号
    if (connectedCount <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must keep at least one connected account')));
      return;
    }

    // 如果断开后只剩邮箱，且没有设置密码，需要先设置密码
    final willOnlyHaveEmail = connectedCount == 2 && isEmailConnected;
    if (willOnlyHaveEmail && !hasPassword) {
      _showSetPasswordFirstDialog();
      return;
    }

    // 确认断开（弹窗样式对齐设计图：白卡 + 右上 X + 居中标题/说明 + 等宽双按钮）
    final confirmed = await _showBrandConfirmDialog(
      title: 'Disconnect GitHub',
      message: 'Are you sure you want to disconnect your GitHub account?',
      confirmText: 'Disconnect',
    );

    if (confirmed == true) {
      try {
        await context.read<UserStore>().unlinkAccount(provider: 'github');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('GitHub disconnected successfully')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to disconnect GitHub: $e')));
      }
    }
  }

  void _showSetPasswordFirstDialog() async {
    final confirmed = await _showBrandConfirmDialog(
      title: 'Please set a password first',
      message: 'Set password before disconnecting this account',
      confirmText: 'Set Password',
    );
    if (confirmed == true && mounted) {
      _pushChangePassword(false);
    }
  }

  /// 品牌风格确认弹窗（对齐设计图）：白色圆角卡 + 右上 X 关闭 +
  /// 居中加粗标题 + 灰色居中说明 + 底部等宽双按钮（描边 Cancel + 黑底主按钮）。
  Future<bool?> _showBrandConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context, false),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 22, color: Color(0xFF171717)),
                  ),
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontFamily: 'Geist',
                  color: Color(0xFF9E9B93),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E2DC)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                          color: Color(0xFF9E9B93),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtil.textColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
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
    );
  }
}
