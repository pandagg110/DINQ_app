import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';
import '../../widgets/account/change_domain_modal.dart';

class SettingsDinqCardPage extends StatelessWidget {
  const SettingsDinqCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final myFlow = userStore.myFlow;
    final currentDomain = myFlow?.status == 'success' ? myFlow?.domain : null;

    return Scaffold(
      appBar: DefaultAppBar(context, titleString: "DINQ Card", backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note 提示框
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: changing your DINQ ID will also change your QR code and URL',
                style: TextStyle(fontSize: 12, color: ColorUtil.textColor, fontFamily: 'Geist'),
              ),
            ),
            const SizedBox(height: 20),
            // Custom domain 标签
            Text(
              'Custom domain',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorUtil.textColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            // Domain 输入框（只读显示）
            Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E6E6)),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  currentDomain != null ? 'dinq.me/$currentDomain' : 'No active domain',
                  style: TextStyle(
                    fontSize: 14,
                    color: currentDomain != null ? ColorUtil.textColor : ColorUtil.sub2TextColor,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Change 按钮
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _showChangeDomainModal(context, currentDomain),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtil.textColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
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

  void _showChangeDomainModal(BuildContext context, String? currentDomain) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeDomainModal(
        currentDomain: currentDomain ?? '',
        onSuccess: (newDomain) {
          // 更新 UserStore 中的 myFlow
          context.read<UserStore>().getFlow();
        },
      ),
    );
  }
}
