import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// 创建组织（对齐 web POST /org）。名称 + Handle(slug，带可用性检查) + 类型 + 简介。
class OrganizationCreatePage extends StatefulWidget {
  const OrganizationCreatePage({super.key});

  @override
  State<OrganizationCreatePage> createState() => _OrganizationCreatePageState();
}

class _OrganizationCreatePageState extends State<OrganizationCreatePage> {
  final _service = AccountService();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Timer? _slugDebounce;
  bool? _slugAvailable;
  bool _checkingSlug = false;
  bool _submitting = false;
  String _type = 'company';

  static const _types = [
    'community', 'company', 'lab', 'opensource', 'event', 'investor', 'incubator', 'media',
  ];

  @override
  void dispose() {
    _slugDebounce?.cancel();
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onSlugChanged(String v) {
    _slugDebounce?.cancel();
    final slug = v.trim();
    if (slug.isEmpty) {
      setState(() => _slugAvailable = null);
      return;
    }
    setState(() => _checkingSlug = true);
    _slugDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final ok = await _service.checkOrgSlug(slug);
        if (!mounted) return;
        setState(() {
          _slugAvailable = ok;
          _checkingSlug = false;
        });
      } catch (_) {
        if (mounted) setState(() => _checkingSlug = false);
      }
    });
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _slugCtrl.text.trim().isNotEmpty &&
      _slugAvailable != false &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await _service.createOrg(
        name: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim(),
        orgType: _type,
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack('Organization created');
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Create failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Create organization'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _label('Name'),
          _input(_nameCtrl, 'e.g. DINQ Labs', onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          _label('Handle'),
          _input(_slugCtrl, 'your-org', prefix: 'dinq.me/', onChanged: _onSlugChanged),
          if (_slugCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _slugHint(),
          ],
          const SizedBox(height: 16),
          _label('Type'),
          _typeSelector(),
          const SizedBox(height: 16),
          _label('Description (optional)'),
          _input(_descCtrl, 'What is this organization about?', maxLines: 3),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _canSubmit ? _submit : null,
            child: Opacity(
              opacity: _canSubmit ? 1 : 0.5,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorUtil.textColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_submitting ? 'Creating…' : 'Create',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
      );

  Widget _input(TextEditingController c, String hint,
      {String? prefix, int maxLines = 1, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
        prefixText: prefix,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _slugHint() {
    if (_checkingSlug) {
      return const Text('Checking…', style: TextStyle(fontSize: 12, color: DinqTokens.textTertiary));
    }
    if (_slugAvailable == true) {
      return const Text('Available', style: TextStyle(fontSize: 12, color: Color(0xFF16803D)));
    }
    if (_slugAvailable == false) {
      return const Text('Already taken', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)));
    }
    return const SizedBox.shrink();
  }

  Widget _typeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in _types)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _type = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _type == t ? ColorUtil.textColor : DinqTokens.bgCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _type == t ? ColorUtil.textColor : DinqTokens.borderL),
              ),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _type == t ? Colors.white : ColorUtil.textColor)),
            ),
          ),
      ],
    );
  }
}
