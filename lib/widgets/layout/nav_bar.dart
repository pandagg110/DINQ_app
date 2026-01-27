import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.onBack,
    required this.title,
  });

  final VoidCallback onBack;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // 只处理顶部状态栏，不处理底部导航栏
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          children: [
            // Title (custom widget) - centered
            Center(
              child: title,
            ),
            // Back button - positioned on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF111827),
                ),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

