import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/task_service.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/default_app_bar.dart';

/// 创建 Radar（对齐 web CreateTaskDialog 的对话式流程）：
/// 描述需求 → /scheduler/create-task mode=check 反复追问细化维度 →
/// 维度齐备 → 执行设置(频率/数量/邮箱) → mode=create 启动。
class TalentRadarCreatePage extends StatefulWidget {
  const TalentRadarCreatePage({super.key});

  @override
  State<TalentRadarCreatePage> createState() => _TalentRadarCreatePageState();
}

enum _Stage { describe, refine, settings }

class _TalentRadarCreatePageState extends State<TalentRadarCreatePage> {
  final _service = TaskService();
  final _promptCtrl = TextEditingController();
  final _refineCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  _Stage _stage = _Stage.describe;
  bool _submitting = false;
  String? _sessionId;
  String _prompt = '';
  String _followUpQuestion = '';
  List<String> _quickOptions = [];
  final Set<String> _selected = {};
  Map<String, dynamic> _dimensions = {};

  static const _frequencies = ['Hourly', 'Daily', 'Weekly', 'Monthly'];
  static const _quantities = ['10', '20', '30', '50'];
  String _frequency = 'Daily';
  String _quantity = '20';

  static const _ink = Color(0xFF1C1917);
  static const _muted = Color(0xFF78716C);

  String get _userId => context.read<UserStore>().user?.user.id ?? '';

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _handle(Map<String, dynamic> resp) {
    final sid = resp['task_session_id']?.toString();
    if (sid != null && sid.isNotEmpty) _sessionId = sid;
    if (resp['dimensions'] is Map) {
      _dimensions = {..._dimensions, ...Map<String, dynamic>.from(resp['dimensions'] as Map)};
    }
    // 与人才搜索无关
    if (resp['talent_search_relevant'] == false) {
      _snack('This doesn\'t look like a talent search. Try describing a role to hire.');
      setState(() => _stage = _Stage.describe);
      return;
    }
    final ready = resp['dimensions_ready'] == true;
    final followUp = (resp['follow_up_question'] ?? '').toString();
    if (ready || followUp.isEmpty) {
      setState(() => _stage = _Stage.settings);
      return;
    }
    setState(() {
      _followUpQuestion = followUp;
      _quickOptions =
          (resp['quick_options'] as List?)?.map((e) => e.toString()).toList() ?? const [];
      _selected.clear();
      _refineCtrl.clear();
      _stage = _Stage.refine;
    });
  }

  Future<void> _call({
    required String description,
    String mode = 'check',
    String? frequency,
    int? quantity,
    String? email,
  }) async {
    if (_userId.isEmpty) {
      _snack('Not signed in');
      return;
    }
    setState(() => _submitting = true);
    try {
      final resp = await _service.createSchedulerTask(
        description: description,
        userId: _userId,
        mode: mode,
        taskSessionId: _sessionId,
        searchFrequency: frequency,
        searchQuantity: quantity,
        email: email,
      );
      if (!mounted) return;
      if (mode == 'create') {
        final taskId = resp['task_id'];
        if (taskId != null) {
          _snack('Radar created');
          Navigator.pop(context, true);
          return;
        }
        _snack('Create failed, please retry');
        return;
      }
      _handle(resp);
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _start() {
    final p = _promptCtrl.text.trim();
    if (p.isEmpty) return;
    _prompt = p;
    _call(description: p);
  }

  void _submitRefine() {
    final answer = [
      ..._selected,
      if (_refineCtrl.text.trim().isNotEmpty) _refineCtrl.text.trim(),
    ].join(', ');
    if (answer.isEmpty) return;
    _call(description: answer);
  }

  String _buildCreateDescription() {
    const keys = [
      'professional_field',
      'location_region',
      'role_track',
      'years_experience',
      'education_background',
      'compensation_range',
    ];
    final parts = [
      for (final k in keys)
        if ((_dimensions[k] ?? '').toString().trim().isNotEmpty) _dimensions[k].toString().trim()
    ];
    final refined = parts.join(', ');
    if (refined.isEmpty) return _prompt;
    return _prompt.isEmpty ? refined : '$_prompt\n\nRefined criteria: $refined';
  }

  void _launch() {
    _call(
      description: _buildCreateDescription(),
      mode: 'create',
      frequency: _frequency,
      quantity: int.tryParse(_quantity) ?? 20,
      email: _emailCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Create Radar'),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _submitting,
          child: switch (_stage) {
            _Stage.describe => _describe(),
            _Stage.refine => _refine(),
            _Stage.settings => _settings(),
          },
        ),
      ),
    );
  }

  Widget _describe() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Tell us who you need",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 8),
        const Text('Describe the role in plain language. AI will refine the criteria with you.',
            style: TextStyle(fontSize: 14, height: 1.4, color: _muted)),
        const SizedBox(height: 20),
        TextField(
          controller: _promptCtrl,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Senior ML engineers with LLM experience in the Bay Area',
            hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton(_submitting ? 'Thinking…' : 'Start', _start),
      ],
    );
  }

  Widget _refine() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Refine the search',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 12),
        Text(_followUpQuestion,
            style: const TextStyle(fontSize: 15, height: 1.45, color: _ink)),
        const SizedBox(height: 16),
        if (_quickOptions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in _quickOptions)
                _chip(o, _selected.contains(o), () {
                  setState(() => _selected.contains(o) ? _selected.remove(o) : _selected.add(o));
                }),
            ],
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _refineCtrl,
          decoration: InputDecoration(
            hintText: 'Or type your own answer',
            hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton(_submitting ? 'Thinking…' : 'Continue', _submitRefine),
      ],
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Execution settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        const Text('How often the Radar runs and how many candidates per scan.',
            style: TextStyle(fontSize: 14, color: _muted)),
        const SizedBox(height: 20),
        const Text('Frequency',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _frequencies)
              _chip(f, _frequency == f, () => setState(() => _frequency = f)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Candidates per search',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _quantities)
              _chip(q, _quantity == q, () => setState(() => _quantity = q)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Notification email (optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'you@company.com',
            hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton(_submitting ? 'Launching…' : 'Launch Radar', _launch),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _ink : DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _ink : DinqTokens.borderL),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _ink)),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _submitting ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
