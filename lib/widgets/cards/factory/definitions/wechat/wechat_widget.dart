import 'package:flutter/material.dart';
import 'wechat_layouts.dart';

class WeChatWidget extends StatelessWidget {
  const WeChatWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final username = (metadata['username'] as String?) ?? '';
    final imageUrl = (metadata['imageUrl'] as String?) ?? '';

    switch (size) {
      case '2x2':
        return WeChatLayouts.build2x2Layout(
          username: username,
        );
      case '2x4':
        return WeChatLayouts.build2x4Layout(
          username: username,
          imageUrl: imageUrl,
        );
      case '4x2':
        return WeChatLayouts.build4x2Layout(
          username: username,
          imageUrl: imageUrl,
        );
      case '4x4':
        return WeChatLayouts.build4x4Layout(
          username: username,
          imageUrl: imageUrl,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

