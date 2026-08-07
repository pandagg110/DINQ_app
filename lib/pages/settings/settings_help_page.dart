import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/app_update/version_check_flow.dart';
import '../../widgets/common/default_app_bar.dart';

/// Settings → Help & Support。
class SettingsHelpPage extends StatefulWidget {
  const SettingsHelpPage({super.key});

  @override
  State<SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<SettingsHelpPage> {
  static const _supportEmail = 'support@dinq.me';
  static const _websiteUrl = 'https://dinq.me/';

  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${info.version}(${info.buildNumber})';
    });
  }

  void _openWebView(String url, String title) {
    context.push(
      '/webview',
      extra: {'url': url, 'navTitle': title},
    );
  }

  Future<void> _openEmail() async {
    // 让用户在“默认发送 / 复制邮箱 / 取消”中选择。
    if (!mounted) return;
    final shouldLaunch = await showModalBottomSheet<bool?>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (dialogContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.mail_outline, color: Color(0xFF171717)),
                    SizedBox(width: 10),
                    Text(
                      'Use default mail app',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.of(dialogContext).pop(true),
            ),
            const Divider(height: 1, thickness: 1),
            ListTile(
              title: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.copy, color: Color(0xFF171717)),
                    SizedBox(width: 10),
                    Text(
                      'Copy email address',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.of(dialogContext).pop(false);
                Clipboard.setData(ClipboardData(text: _supportEmail)).then((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text('Email address copied'),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
            const Divider(height: 1, thickness: 1),
            ListTile(
              title: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onTap: () => Navigator.of(dialogContext).pop(null),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (shouldLaunch != true) return;

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开邮件客户端，请手动发送')),
      );
    }
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_websiteUrl);
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!launched && mounted) {
      TopToastUtil.showError(
        context: context,
        title: 'Unable to open website',
        description: 'Please open $_websiteUrl manually.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtil.pageBgColor,
      appBar: DefaultAppBar(
        context,
        titleString: 'Help & Support',
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          _buildBrand(),
          const SizedBox(height: 40),
          _card([
            _tile(
              icon: Icons.terminal_rounded,
              label: 'Version',
              trailingText: _versionLabel.isEmpty ? '—' : _versionLabel,
              showChevron: false,
              onTap: () => showManualVersionCheckFlow(context),
            ),
          ]),
          const SizedBox(height: 16),
          _card([
            _tile(
              icon: Icons.verified_user_outlined,
              label: 'Privacy Policy',
              onTap: () => _openWebView(privacyUrl, 'Privacy Policy'),
            ),
            _divider(),
            _tile(
              icon: Icons.description_outlined,
              label: 'Terms',
              onTap: () => _openWebView(termsUrl, 'Terms of Service'),
            ),
            _divider(),
            _tile(
              icon: Icons.mail_outline_rounded,
              label: _supportEmail,
              onTap: _openEmail,
            ),
            _divider(),
            _tile(
              icon: Icons.language_rounded,
              label: _websiteUrl,
              onTap: _openWebsite,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A101828),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/logo/dinq-black.svg',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'DINQ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ColorUtil.textColor,
            fontFamily: 'Geist',
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF3F2EF),
        indent: 52,
        endIndent: 16,
      );

  Widget _tile({
    required IconData icon,
    required String label,
    String? trailingText,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ColorUtil.textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: ColorUtil.textColor,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtil.sub2TextColor,
                  fontFamily: 'Geist',
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBAB3)),
            ],
          ],
        ),
      ),
    );
  }
}
