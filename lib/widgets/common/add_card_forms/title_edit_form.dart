import 'package:flutter/material.dart';
import '../../../models/card_models.dart';
import '../../cards/factory/card_definition.dart';
import '../asset_icon.dart';
import '../../../utils/icon_mapping.dart' as icon_mapping;
import 'card_form_base.dart';

/// TITLE 卡片编辑表单：与添加弹框一致的样式（图标 + 输入框一行）。
/// getFormData() 直接返回最新的完整 CardData（Map，供 CardData.fromJson 使用）。
class TitleEditForm extends CardFormBase {
  TitleEditForm({
    required this.controller,
    required this.currentData,
    FocusNode? focusNode,
  }) : _focusNode = focusNode ?? FocusNode();

  final TextEditingController controller;
  final CardData currentData;
  final FocusNode _focusNode;

  @override
  Widget build(BuildContext context, CardDefinition definition) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIcon(definition),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Add a title...',
              hintStyle: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF171717), width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF171717),
            ),
          ),
        ),
      ],
    );
  }

  /// 返回最新的完整 CardData 数据（Map），弹框可直接 CardData.fromJson 后 updateCardData。
  @override
  Future<Map<String, dynamic>?> getFormData() async {
    final d = currentData;
    return {
      'id': d.id,
      'type': d.type,
      'title': d.title,
      'description': d.description,
      'metadata': {...d.metadata, 'title': controller.text.trim()},
      'status': d.status,
    };
  }

  Widget _buildIcon(CardDefinition def) {
    final icon = def.icon;
    if (icon.startsWith('i-lucide-') || icon.startsWith('i-mdi:')) {
      return _iconFallback();
    }
    final asset = icon.startsWith('/') ? icon.substring(1) : icon;
    String finalAsset = asset;
    if (asset.contains('icons/social-icons/')) {
      finalAsset = icon_mapping.mapSvgToPng(asset);
    }
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AssetIcon(asset: finalAsset, size: 28),
    );
  }

  Widget _iconFallback() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.title, size: 24, color: Colors.grey.shade700),
    );
  }
}
