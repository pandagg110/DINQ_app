import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/task_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/default_app_bar.dart';

/// Radar 详情页（对齐 web talent-radar/[taskId]，3 Tab）：
/// Details（状态/条件/指标/新增候选人）/ Logs（搜索日志）/ Credits（消耗）。
/// 覆盖 Notion：Radar 详情 + 新增候选人 + 搜索日志 + Credits 消耗。
class TalentRadarDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;
  const TalentRadarDetailPage({super.key, required this.task});

  @override
  State<TalentRadarDetailPage> createState() => _TalentRadarDetailPageState();
}

class _TalentRadarDetailPageState extends State<TalentRadarDetailPage> {
  final _service = TaskService();
  late Map<String, dynamic> _task;
  List<dynamic> _events = [];
  bool _eventsLoading = true;
  String? _eventsError;

  static const _ink = Color(0xFF1C1917);
  static const _muted = Color(0xFF78716C);

  String get _id => (_task['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _refreshTask();
    _loadEvents();
  }

  Future<void> _refreshTask() async {
    try {
      final t = await _service.getTask(_id);
      if (!mounted || t.isEmpty) return;
      setState(() => _task = {..._task, ...t});
    } catch (_) {/* 用列表传入的数据兜底 */}
  }

  Future<void> _loadEvents() async {
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });
    try {
      final ev = await _service.getTaskEvents(_id);
      if (!mounted) return;
      setState(() {
        _events = ev;
        _eventsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eventsError = 'No history is available for this radar yet.';
        _eventsLoading = false;
      });
    }
  }

  int _int(String key) => int.tryParse((_task[key] ?? '0').toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final title = (_task['prompt'] ?? _task['name'] ?? 'Talent Radar').toString();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: DinqTokens.bgPage,
        appBar: DefaultAppBar(context, titleString: 'Radar detail'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
                  ),
                  const SizedBox(width: 8),
                  _statusPill((_task['status'] ?? 'pending').toString()),
                ],
              ),
            ),
            const TabBar(
              labelColor: _ink,
              unselectedLabelColor: _muted,
              indicatorColor: _ink,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: [Tab(text: 'Details'), Tab(text: 'Logs'), Tab(text: 'Credits')],
            ),
            Expanded(
              child: TabBarView(
                children: [_detailsTab(), _logsTab(), _creditsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== Details ==============
  Widget _detailsTab() {
    final scanned = _int('scanned_candidates');
    final highMatch = _int('high_match_candidates');
    final results = _int('result_count') != 0 ? _int('result_count') : _int('results_count');
    final todayNew = _int('today_new_candidates');
    final schedule = (_task['schedule_expr'] ?? _task['schedule'] ?? '').toString();
    final nextRun = (_task['next_run_at'] ?? '').toString();
    final lastRun = (_task['last_run_at'] ?? '').toString();
    final candidates = _candidates();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 指标
        Row(
          children: [
            Expanded(child: _metric('SCANNED', '$scanned')),
            const SizedBox(width: 10),
            Expanded(child: _metric('HIGH MATCH', '$highMatch')),
            const SizedBox(width: 10),
            Expanded(child: _metric('RESULTS', '$results')),
          ],
        ),
        const SizedBox(height: 16),
        // 搜索条件 / 运行状态
        _section('Search criteria', [
          _kv('Prompt', (_task['prompt'] ?? '—').toString()),
          if (schedule.isNotEmpty) _kv('Frequency', schedule),
        ]),
        const SizedBox(height: 12),
        _section('Run status', [
          _kv('Status', (_task['status'] ?? '—').toString()),
          if (lastRun.isNotEmpty) _kv('Last run', _fmt(lastRun)),
          if (nextRun.isNotEmpty) _kv('Next run', _fmt(nextRun)),
        ]),
        const SizedBox(height: 16),
        // 新增候选人
        Row(
          children: [
            const Text('Candidates',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(width: 8),
            if (todayNew > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Text('+$todayNew new today',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (candidates.isEmpty)
          _empty('No candidates yet', 'New matches from this radar will appear here.')
        else
          for (final c in candidates) _candidateRow(Map<String, dynamic>.from(c as Map)),
      ],
    );
  }

  List<dynamic> _candidates() {
    final r = _task['result'] ?? _task['candidates'] ?? _task['results'];
    if (r is List) return r;
    if (r is Map && r['candidates'] is List) return r['candidates'] as List;
    return const [];
  }

  Widget _candidateRow(Map<String, dynamic> c) {
    final name = (c['name'] ?? c['full_name'] ?? 'Candidate').toString();
    final meta = (c['full_position'] ?? c['headline'] ?? c['title'] ?? '').toString();
    final domain = (c['domain'] ?? '').toString();
    final github = (c['github_url'] ?? c['github'] ?? '').toString();
    final scholar = (c['scholar_url'] ?? c['scholar'] ?? '').toString();
    final linkedin = (c['linkedin_url'] ?? c['linkedin'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8880))),
          ],
          if (domain.isNotEmpty || github.isNotEmpty || scholar.isNotEmpty || linkedin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (domain.isNotEmpty) _pill('dinq.me/$domain', () => _open('https://dinq.me/$domain')),
                if (github.isNotEmpty) _pill('GitHub', () => _open(github)),
                if (scholar.isNotEmpty) _pill('Scholar', () => _open(scholar)),
                if (linkedin.isNotEmpty) _pill('LinkedIn', () => _open(linkedin)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============== Logs ==============
  Widget _logsTab() {
    if (_eventsLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_eventsError != null || _events.isEmpty) {
      return _empty('No logs yet', _eventsError ?? 'No history is available for this radar yet.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final e in _events) _logRow(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }

  Widget _logRow(Map<String, dynamic> e) {
    final type = (e['type'] ?? 'event').toString();
    final time = _fmt((e['created_at'] ?? '').toString());
    final data = e['data'];
    String summary = '';
    if (data is Map) {
      final scanned = data['scanned'] ?? data['scanned_count'];
      final hit = data['hit'] ?? data['hit_count'] ?? data['matched'];
      summary = [
        if (scanned != null) 'Scanned $scanned',
        if (hit != null) 'Hit $hit',
      ].join(' · ');
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, size: 18, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(summary, style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFFA8A29E))),
        ],
      ),
    );
  }

  // ============== Credits ==============
  Widget _creditsTab() {
    final cost = double.tryParse((_task['cost_usd'] ?? '0').toString()) ?? 0;
    if (cost <= 0) {
      return _empty('No credit records yet', 'No credit records are available for this radar yet.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Credits', [
          _kv('Total spent', '\$${cost.toStringAsFixed(2)}'),
        ]),
      ],
    );
  }

  // ============== 通用 ==============
  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: _muted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(k, style: const TextStyle(fontSize: 13, color: _muted)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, color: _ink))),
        ],
      ),
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: DinqTokens.bgSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _ink)),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color fg;
    Color bg;
    String label;
    switch (status) {
      case 'active':
      case 'running':
      case 'scheduled':
      case 'pending':
        fg = const Color(0xFF16803D);
        bg = const Color(0xFFDCFCE7);
        label = 'Active';
        break;
      case 'paused':
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFEF3C7);
        label = 'Paused';
        break;
      case 'completed':
        fg = const Color(0xFF1D4ED8);
        bg = const Color(0xFFDBEAFE);
        label = 'Completed';
        break;
      case 'failed':
      case 'cancelled':
        fg = const Color(0xFFDC2626);
        bg = const Color(0xFFFEE2E2);
        label = 'Failed';
        break;
      default:
        fg = _muted;
        bg = const Color(0xFFF5F5F4);
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(36)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _empty(String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCDC9C2)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 4),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _muted)),
          ],
        ),
      ),
    );
  }

  String _fmt(String s) {
    final d = DateTime.tryParse(s)?.toLocal();
    if (d == null) return s;
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${m[d.month - 1]} ${d.day}, $hh:$mm';
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
