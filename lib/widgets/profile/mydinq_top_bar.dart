import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../common/base_page.dart';
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
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle:
              const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          leading: IconButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            icon: const Padding(
              padding: EdgeInsets.all(4),
              child: AssetImageView('nav_back', width: 20, height: 20),
            ),
            onPressed: () {
              if (onBack != null) {
                onBack();
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/me');
              }
            },
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
            IconButton(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onPressed: isSaving ? null : onShare,
              icon: Padding(
                padding: const EdgeInsets.all(4),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF171717),
                        ),
                      )
                    : const Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Color(0xFF171717),
                      ),
              ),
            ),
          ],
        );
}
