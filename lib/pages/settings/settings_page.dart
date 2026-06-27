import 'package:cached_network_image/cached_network_image.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';

/// Settings 页（对齐线上 set_b 设计）：
/// Profile 卡（头像+名+handle）+ Account / Verification(Basic) / DINQ Page /
/// API Keys + 底部 Sign out。（Language 暂无 i18n 不放；Subscriptions 移至 My 首页卡片）
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final data = userStore.user?.userData;
    final name = data?.name ?? '';
    final domain = data?.domain ?? '';
    final avatar = data?.avatarUrl ?? '';

    return Scaffold(
      appBar: DefaultAppBar(context, titleString: 'Settings', backgroundColor: Colors.transparent),
      backgroundColor: ColorUtil.pageBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  // Profile 卡
                  _card([
                    _profileRow(context, name, domain, avatar),
                  ]),
                  const SizedBox(height: 16),
                  // 菜单卡
                  _card([
                    _tile(context, Icons.account_circle_outlined, 'Account', '/settings/account'),
                    _divider(),
                    _tile(context, Icons.verified_user_outlined, 'Verification',
                        '/settings/verification', showBasic: true),
                    _divider(),
                    _tile(context, Icons.web_outlined, 'DINQ Page', '/settings/dinqcard'),
                    _divider(),
                    _tile(context, Icons.vpn_key_outlined, 'API Keys', '/me/api-keys'),
                  ]),
                ],
              ),
            ),
            // Sign out
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  userStore.logout();
                  context.go('/signin');
                },
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Sign out',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: ColorUtil.textColor,
                          fontFamily: 'Geist')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF3F2EF), indent: 16, endIndent: 16);

  Widget _profileRow(BuildContext context, String name, String domain, String avatar) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/settings/profile'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFF2F0EC), shape: BoxShape.circle),
              child: avatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatar, width: 48, height: 48, fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Text(initial,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: ColorUtil.textColor)))
                  : Text(initial,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: ColorUtil.textColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Me' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700, color: ColorUtil.textColor,
                          fontFamily: 'Geist')),
                  const SizedBox(height: 2),
                  Text('dinq.me/$domain',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: ColorUtil.sub2TextColor, fontFamily: 'Geist')),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBAB3)),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String path,
      {bool showBasic = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ColorUtil.textColor),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 15, color: ColorUtil.textColor, fontFamily: 'Geist')),
            const SizedBox(width: 6),
            if (showBasic)
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Text('Basic',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF1487FA),
                        fontWeight: FontWeight.w500, fontFamily: 'Geist')),
              ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBAB3)),
          ],
        ),
      ),
    );
  }
}
