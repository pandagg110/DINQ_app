import 'package:flutter/material.dart';

import 'base_page.dart';

/// 全局导航栏圆形按钮基座。
/// 对齐设计：左侧圆形返回按钮 + 右侧圆形操作按钮，全局统一。
class _DinqCircleButtonShell extends StatelessWidget {
  const _DinqCircleButtonShell({
    required this.child,
    required this.onTap,
    required this.background,
    this.border,
    this.size = 40,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color background;
  final Color? border;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border:
              border == null ? null : Border.all(color: border!, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 左侧圆形返回按钮：白底圆形 + 返回箭头。
class DinqCircleBackButton extends StatelessWidget {
  const DinqCircleBackButton({super.key, required this.onTap, this.size = 40});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _DinqCircleButtonShell(
      onTap: onTap,
      background: Colors.white,
      border: const Color(0xFFEAE8E3),
      size: size,
      child: const AssetImageView('nav_back', width: 18, height: 18),
    );
  }
}

/// 右侧圆形操作按钮。
/// primary=true → 黑底白 icon（主操作，如新增 +）；否则白底深色 icon（次操作，如分享）。
class DinqCircleActionButton extends StatelessWidget {
  const DinqCircleActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.loading = false,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color fg = primary ? Colors.white : const Color(0xFF171717);
    final Color bg = primary ? const Color(0xFF171717) : Colors.white;
    return _DinqCircleButtonShell(
      onTap: loading ? null : onTap,
      background: bg,
      border: primary ? null : const Color(0xFFEAE8E3),
      size: size,
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          : Icon(icon, size: 20, color: fg),
    );
  }
}
