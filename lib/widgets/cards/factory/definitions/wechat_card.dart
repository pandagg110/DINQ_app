import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'wechat/wechat_widget.dart';

class WeChatCardDefinition extends CardDefinition {
  @override
  String get type => 'WECHAT';

  @override
  String get icon => '/icons/social-icons/WeChat.svg';

  @override
  String get name => 'WeChat';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
      );

  @override
  Future<Map<String, dynamic>>? create() async {
    return {
      'username': '',
      'imageUrl': '',
    };
  }

  @override
  String? validate(Map<String, dynamic> metadata) {
    final username = metadata['username']?.toString() ?? '';
    if (username.trim().isEmpty) {
      return 'WeChat username is required';
    }
    return null; // Validation passed
  }

  @override
  Widget render(CardRenderParams params) {
    return WeChatWidget(
      card: params.card,
      size: params.size,
    );
  }
}

