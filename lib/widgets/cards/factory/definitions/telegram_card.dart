import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'telegram/telegram_widget.dart';

class TelegramCardDefinition extends CardDefinition {
  @override
  String get type => 'TELEGRAM';

  @override
  String get icon => '/icons/social-icons/Telegram.svg';

  @override
  String get name => 'Telegram';

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
      return 'Telegram username is required';
    }
    return null; // Validation passed
  }

  @override
  Widget render(CardRenderParams params) {
    return TelegramWidget(
      card: params.card,
      size: params.size,
    );
  }
}

