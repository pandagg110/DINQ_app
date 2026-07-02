import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/dinq_tokens.dart';
import '../common/dinq_nav_buttons.dart';
import 'preview_edit_toggle.dart';

/// 对齐 Resume 页 `DefaultAppBar` 高度/位置，内容对齐 Web `mydinq/layout.tsx`。
class MyDinqTopBar extends AppBar {
  MyDinqTopBar(
    BuildContext context, {
    super.key,
    required bool isPageTab,
    required ValueChanged<bool> onTabChanged,
    required VoidCallback onShare,
    bool isSaving = false,
    VoidCallback? onBack,
  }) : super(
          backgroundColor: DinqTokens.bgPage,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle:
              const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: DinqCircleBackButton(
                onTap: () {
                  if (onBack != null) {
                    onBack();
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/me');
                  }
                },
              ),
            ),
          ),
          title: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
            child: PreviewEditToggle(
              key: const ValueKey('preview_edit_toggle'),
              style: PreviewEditToggleStyle.myDinq,
              isPreviewMode: isPageTab,
              onPreviewModeChanged: onTabChanged,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: DinqCircleActionButton(
                  icon: Icons.share_outlined,
                  loading: isSaving,
                  onTap: onShare,
                ),
              ),
            ),
          ],
        );
}
