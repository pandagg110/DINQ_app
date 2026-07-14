import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/message_models.dart';
import '../../services/message_service.dart';

/// 「发起组队」表单（对齐 web CreateTeamRecruitModal.tsx）。
/// 字段：Title（必填，<=100）/ Description（可选，<=500 带计数）/
/// Team size（2-50，默认 5）；提交走 POST /conversations/:id/team-recruit，
/// 成功后返回 message_type=team_recruit 的 Message 给调用方入列。
/// 移动端用底部弹层承载（web AdaptiveModal 在移动端同为 bottom drawer）。
class CreateTeamRecruitSheet extends StatefulWidget {
  const CreateTeamRecruitSheet({super.key, required this.conversationId});

  final String conversationId;

  /// 弹出表单；创建成功返回新 Message，取消返回 null。
  static Future<Message?> show({
    required BuildContext context,
    required String conversationId,
  }) {
    return showModalBottomSheet<Message>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        // 键盘弹起时上推表单
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CreateTeamRecruitSheet(conversationId: conversationId),
      ),
    );
  }

  @override
  State<CreateTeamRecruitSheet> createState() => _CreateTeamRecruitSheetState();
}

class _CreateTeamRecruitSheetState extends State<CreateTeamRecruitSheet> {
  // 与 web CreateTeamRecruitModal 的常量一致
  static const _minMembers = 2;
  static const _maxMembers = 50;
  static const _defaultMembers = 5;

  final _service = MessageService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _sizeController = TextEditingController(text: '$_defaultMembers');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
    _sizeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  int get _teamSize => int.tryParse(_sizeController.text.trim()) ?? 0;

  bool get _canSubmit =>
      !_submitting &&
      _titleController.text.trim().isNotEmpty &&
      _teamSize >= _minMembers &&
      _teamSize <= _maxMembers;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        if (_descController.text.trim().isNotEmpty)
          'description': _descController.text.trim(),
        'max_members': _teamSize,
      };
      final resp = await _service.createTeamRecruit(widget.conversationId, data);
      // web 契约：响应即完整 Message（message_type=team_recruit）；
      // 防御性兼容 { message: {...} } 包裹形态。
      final raw = resp['id'] != null
          ? resp
          : (resp['message'] is Map
              ? Map<String, dynamic>.from(resp['message'] as Map)
              : resp);
      final message = Message.fromJson(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Team recruit posted')));
      Navigator.of(context).pop(message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to post recruit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏（web AdaptiveModal title: "Start team recruit"）
            Row(
              children: [
                const Expanded(
                  child: Text('Start team recruit',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717))),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded,
                      size: 22, color: Color(0xFF9E9B93)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title *
            _label('Title', required: true),
            const SizedBox(height: 6),
            _input(
              controller: _titleController,
              hint: 'Need 4 devs for the Q2 migration',
              maxLength: 100,
              autofocus: true,
            ),
            const SizedBox(height: 20),

            // Description
            _label('Description'),
            const SizedBox(height: 6),
            _input(
              controller: _descController,
              hint: 'Looking for folks with Go + Postgres experience. Weekend sprint.',
              maxLength: 500,
              maxLines: 3,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_descController.text.length}/500',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E9B93))),
            ),
            const SizedBox(height: 12),

            // Team size *
            _label('Team size', required: true),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: _input(
                    controller: _sizeController,
                    hint: '$_defaultMembers',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('people total (including yourself)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93))),
                ),
              ],
            ),
            if (_sizeController.text.isNotEmpty &&
                (_teamSize < _minMembers || _teamSize > _maxMembers))
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Team size must be between 2 and 50',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE24B3C))),
              ),
            const SizedBox(height: 24),

            // Cancel / Post recruit
            Row(
              children: [
                Expanded(
                  child: _button(
                    label: 'Cancel',
                    onTap: _submitting ? null : () => Navigator.of(context).pop(),
                    background: Colors.white,
                    foreground: const Color(0xFF171717),
                    border: const Color(0xFFEEEDE9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _button(
                    label: _submitting ? 'Posting…' : 'Post recruit',
                    onTap: _canSubmit ? _submit : null,
                    background: const Color(0xFF171717),
                    foreground: Colors.white,
                    loading: _submitting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF171717)),
        children: [
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE24B3C))),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    int maxLines = 1,
    bool autofocus = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF171717), fontFamily: 'Geist'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E9B93)),
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF171717)),
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required VoidCallback? onTap,
    required Color background,
    required Color foreground,
    Color? border,
    bool loading = false,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled && border == null
              ? background.withValues(alpha: 0.5)
              : background,
          borderRadius: BorderRadius.circular(10),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
              ),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: foreground)),
          ],
        ),
      ),
    );
  }
}
