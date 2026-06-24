import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/task_service.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_icons.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/dinq_svg_icon.dart';
import 'talent_radar_create_page.dart';
import 'talent_radar_detail_page.dart';

/// Talent Radar Tab（持续找人）。
/// 无 Radar 时显示空状态（还原 my_first_app `_TasksPageOverlay`）；
/// 有 Radar 时显示卡片列表（还原 my_first_app `_TaskCard`：状态徽章 +
/// SCANNED / HIGH MATCH / RESULTS 指标 + new today），支持暂停/恢复/删除。
/// 接口走 TaskService（/tasks）。
class TalentRadarPage extends StatefulWidget {
  const TalentRadarPage({super.key});

  @override
  State<TalentRadarPage> createState() => _TalentRadarPageState();
}

class _TalentRadarPageState extends State<TalentRadarPage> {
  final _service = TaskService();
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWhenReady();
  }

  Future<void> _loadWhenReady() async {
    // 等登录态就绪再拉数据，避免 401
    for (var i = 0; i < 40; i++) {
      if (!mounted) return;
      if (context.read<UserStore>().isLoggedIn()) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final tasks = await _service.listTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      // 拉取失败（含无 task 权限）回落到空状态
      if (!mounted) return;
      setState(() {
        _tasks = [];
        _loading = false;
      });
    }
  }

  Future<void> _showActions(Map<String, dynamic> task) async {
    final id = (task['id'] ?? '').toString();
    final status = (task['status'] ?? '').toString();
    final isPaused = status == 'paused';
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DinqTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              title: Text(isPaused ? 'Resume' : 'Pause'),
              onTap: () => Navigator.pop(ctx, isPaused ? 'resume' : 'pause'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              title: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      switch (action) {
        case 'pause':
          await _service.pauseTask(id);
          break;
        case 'resume':
          await _service.resumeTask(id);
          break;
        case 'delete':
          await _service.deleteTask(id);
          break;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double s = constraints.maxWidth / 430;
          if (_loading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          // 拉取失败（含无 task 权限 4013）时回落到空状态，而非裸报错
          return SafeArea(
            bottom: false,
            child: _tasks.isEmpty ? _emptyState(s) : _list(s),
          );
        },
      ),
    );
  }

  // ============== 有数据：列表 ==============
  Widget _list(double s) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 104 * s),
        children: [
          _PageHeaderTitle(scale: s, title: 'Talent Radar'),
          SizedBox(height: 16 * s),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onCreate,
            child: Container(
              width: double.infinity,
              height: 48 * s,
              decoration: BoxDecoration(
                color: DinqTokens.textPrimary,
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DinqSvgIcon(assetName: DinqIcons.plus, size: 16 * s, color: DinqTokens.bgCard),
                  SizedBox(width: 10 * s),
                  Text('Create Radar',
                      style: TextStyle(
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w600,
                        color: DinqTokens.bgCard,
                      )),
                ],
              ),
            ),
          ),
          SizedBox(height: 16 * s),
          for (final t in _tasks)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * s),
              child: _RadarCard(
                scale: s,
                task: Map<String, dynamic>.from(t as Map),
                onMore: () => _showActions(Map<String, dynamic>.from(t)),
                onTap: () => _openDetail(Map<String, dynamic>.from(t)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TalentRadarCreatePage()),
    );
    if (created == true) await _load();
  }

  Future<void> _openDetail(Map<String, dynamic> task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TalentRadarDetailPage(task: task)),
    );
    if (mounted) await _load();
  }

  // ============== 无数据：空状态（还原 _TasksPageOverlay）==============
  Widget _emptyState(double s) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 104 * s),
      child: Column(
        children: [
          _PageHeaderTitle(scale: s, title: 'Talent Radar'),
          SizedBox(height: 34 * s),
          Container(
            height: 32 * s,
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFEB),
              borderRadius: BorderRadius.circular(999 * s),
              border: Border.all(color: const Color(0xFFE6E5E0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DinqSvgIcon(
                  assetName: DinqIcons.matchSpark,
                  size: 14 * s,
                  color: DinqTokens.textSecondary,
                ),
                SizedBox(width: 8 * s),
                Text(
                  'Automated Recruiting Assistant',
                  style: TextStyle(
                    fontSize: 12 * s,
                    height: 18 / 12,
                    fontWeight: FontWeight.w600,
                    color: DinqTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28 * s),
          Text(
            "Tell us who you need,\nwe'll handle the rest.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30 * s,
              height: 37 / 30,
              letterSpacing: -0.8 * s,
              fontWeight: FontWeight.w600,
              color: DinqTokens.textPrimary,
            ),
          ),
          SizedBox(height: 12 * s),
          Text(
            'Scheduled scans, results sent to your inbox.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15 * s,
              height: 24 / 15,
              fontWeight: FontWeight.w500,
              color: DinqTokens.textSecondary,
            ),
          ),
          SizedBox(height: 24 * s),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onCreate,
            child: Container(
              width: double.infinity,
              height: 56 * s,
              decoration: BoxDecoration(
                color: DinqTokens.textPrimary,
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DinqSvgIcon(assetName: DinqIcons.plus, size: 18 * s, color: DinqTokens.bgCard),
                  SizedBox(width: 12 * s),
                  Text(
                    'Create Your First Radar',
                    style: TextStyle(
                      fontSize: 16 * s,
                      height: 22 / 16,
                      fontWeight: FontWeight.w600,
                      color: DinqTokens.bgCard,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20 * s),
          _StepCard(scale: s, step: '1', title: 'Describe', subtitle: 'Describe the role in plain language.'),
          SizedBox(height: 12 * s),
          _StepCard(scale: s, step: '2', title: 'Auto Scan', subtitle: 'Radar runs 24/7 across platforms.'),
          SizedBox(height: 12 * s),
          _StepCard(scale: s, step: '3', title: 'Get Notified', subtitle: 'Matches delivered to your inbox daily.'),
        ],
      ),
    );
  }
}

class _PageHeaderTitle extends StatelessWidget {
  const _PageHeaderTitle({required this.scale, required this.title});

  final double scale;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44 * scale,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17 * scale,
            height: 22 / 17,
            fontWeight: FontWeight.w600,
            color: DinqTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Radar 卡片（还原 my_first_app `_TaskCard`）。
class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.scale,
    required this.task,
    required this.onMore,
    required this.onTap,
  });

  final double scale;
  final Map<String, dynamic> task;
  final VoidCallback onMore;
  final VoidCallback onTap;

  int _int(String key) => int.tryParse((task[key] ?? '0').toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final prompt = (task['prompt'] ?? task['name'] ?? 'Talent search').toString();
    final status = (task['status'] ?? 'pending').toString();
    final scanned = _int('scanned_candidates');
    final highMatch = _int('high_match_candidates');
    final results = _int('result_count') != 0 ? _int('result_count') : _int('results_count');
    final todayNew = _int('today_new_candidates');
    final sb = _statusStyle(status);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onMore,
      child: Container(
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: DinqTokens.borderL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：Talent search pill + 状态徽章 + more
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F4),
                    borderRadius: BorderRadius.circular(36 * s),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radar_rounded, size: 13 * s, color: const Color(0xFF57534E)),
                      SizedBox(width: 5 * s),
                      Text('Talent search',
                          style: TextStyle(
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF57534E),
                          )),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  decoration: BoxDecoration(
                    color: sb.bg,
                    borderRadius: BorderRadius.circular(36 * s),
                  ),
                  child: Text(sb.label,
                      style: TextStyle(
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w600,
                        color: sb.fg,
                      )),
                ),
                SizedBox(width: 4 * s),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMore,
                  child: Icon(Icons.more_horiz_rounded, size: 20 * s, color: DinqTokens.textTertiary),
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            // 标题 + new today
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17 * s,
                        height: 22 / 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1917),
                      )),
                ),
                if (todayNew > 0) ...[
                  SizedBox(width: 8 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4 * s),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Text('+$todayNew new today',
                        style: TextStyle(
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        )),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12 * s),
            // 指标行
            Container(
              padding: EdgeInsets.symmetric(vertical: 12 * s),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF5F5F4)),
                  bottom: BorderSide(color: Color(0xFFF5F5F4)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _Metric(scale: s, label: 'SCANNED', value: '$scanned')),
                  _Divider(scale: s),
                  Expanded(child: _Metric(scale: s, label: 'HIGH MATCH', value: '$highMatch')),
                  _Divider(scale: s),
                  Expanded(child: _Metric(scale: s, label: 'RESULTS', value: '$results')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'active':
      case 'running':
      case 'scheduled':
      case 'pending':
        return const _StatusStyle('Active', Color(0xFF16803D), Color(0xFFDCFCE7));
      case 'paused':
        return const _StatusStyle('Paused', Color(0xFFB45309), Color(0xFFFEF3C7));
      case 'completed':
        return const _StatusStyle('Completed', Color(0xFF1D4ED8), Color(0xFFDBEAFE));
      case 'failed':
      case 'cancelled':
        return const _StatusStyle('Failed', Color(0xFFDC2626), Color(0xFFFEE2E2));
      default:
        return _StatusStyle(status, DinqTokens.textSecondary, const Color(0xFFF5F5F4));
    }
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.fg, this.bg);
  final String label;
  final Color fg;
  final Color bg;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.scale, required this.label, required this.value});

  final double scale;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: DinqTokens.textTertiary,
            )),
        SizedBox(height: 4 * scale),
        Text(value,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            )),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.scale});
  final double scale;
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28 * scale, color: const Color(0xFFF5F5F4));
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.scale,
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 96 * scale,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: DinqTokens.borderL),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52 * scale,
            top: -44 * scale,
            child: Container(
              width: 136 * scale,
              height: 136 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(120 * scale),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(30 * scale, 18 * scale, 24 * scale, 18 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  decoration: BoxDecoration(
                    color: DinqTokens.textPrimary,
                    borderRadius: BorderRadius.circular(999 * scale),
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        height: 20 / 16,
                        fontWeight: FontWeight.w600,
                        color: DinqTokens.bgCard,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 18 * scale),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17 * scale,
                          height: 22 / 17,
                          fontWeight: FontWeight.w600,
                          color: DinqTokens.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: DinqTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
