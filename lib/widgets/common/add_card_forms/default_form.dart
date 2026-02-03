import 'package:flutter/material.dart';
import '../../cards/factory/card_definition.dart';
import '../asset_icon.dart';
import '../../../utils/icon_mapping.dart' as icon_mapping;
import 'card_form_base.dart';

/// 默认/非 Link 类型的表单
class DefaultForm extends CardFormBase {
  final TextEditingController controller;
  final FocusNode focusNode;
  final CardDefinition definition;
  DefaultForm({
    required this.controller,
    required this.focusNode,
    required this.definition,
  });

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
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: _getPlaceholder(definition),
              hintStyle: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  @override
  Future<Map<String, dynamic>?> getFormData() async {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    return {'url': value,'type':definition.type};
  }

  String _getPlaceholder(CardDefinition def) {
    return 'Input URL for ${def.name}';
  }

  Widget _buildIcon(CardDefinition def) {
    final icon = def.icon;
    if (icon.startsWith('i-lucide-') || icon.startsWith('i-mdi:')) {
      return _iconFallback(def.type);
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

  Widget _iconFallback(String type) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.link, size: 24, color: Colors.grey.shade700),
    );
  }
}
