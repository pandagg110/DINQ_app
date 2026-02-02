import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final subscription = userStore.subscription;
    final plan = subscription?.plan ?? 'Free';
    return Scaffold(
      appBar: DefaultAppBar(context, titleString: "Settings", backgroundColor: Colors.transparent),
      backgroundColor: ColorUtil.pageBgColor,
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsTile(context, 'settings_profile', 'Profile', '/settings/profile'),
            _buildSettingsTile(context, 'settings_account', 'Accounts', '/settings/account'),
            _buildSettingsTile(
              context,
              'settings_verification',
              'Verification',
              '/settings/verification',
              showBasic: true,
            ),
            _buildSettingsTile(context, 'settings_card', 'DINQ Card', '/settings/dinqcard'),
            _buildSettingsTile(
              context,
              'remaining_score',
              'Subscriptions',
              '/settings/subscription',
              plan: plan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String imgName,
    String label,
    String path, {
    bool showBasic = false,
    String? plan,
  }) {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: NormalButton(
        onTap: () {
          if (!showBasic) {
            context.push(path);
          }
        },
        child: Row(
          children: [
            AssetImageView(imgName, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontFamily: 'Geist', fontSize: 14, color: ColorUtil.textColor),
            ),
            const SizedBox(width: 4),
            if (showBasic)
              Container(
                height: 18,
                padding: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'Basic',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1487FA),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
            Spacer(),
            if (plan?.isNotEmpty ?? false)
              Text(
                '$plan',
                style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.sub2TextColor),
              ),
            const SizedBox(width: 8),
            AssetImageView("gray_right", width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}
