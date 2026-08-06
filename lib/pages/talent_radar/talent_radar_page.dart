import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_icons.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/dinq_svg_icon.dart';

/// Talent Radar Tab（持续找人）。
/// 功能未发布：整页引导到 Web 体验（[dinq.me/talent-radar]），
/// 不请求 /tasks、不展示任何历史任务。
/// 上线时从 git 历史恢复任务列表/操作逻辑。
class TalentRadarPage extends StatefulWidget {
  const TalentRadarPage({super.key});

  @override
  State<TalentRadarPage> createState() => _TalentRadarPageState();
}

class _TalentRadarPageState extends State<TalentRadarPage> {
  bool _openingWeb = false;

  /// 对齐 analysis 跳转：POST /auth/web-login-ticket →
  /// `{appUrl}/auth/app-login?ticket=...&next=/talent-radar`
  Future<void> _openTalentRadarWeb() async {
    if (_openingWeb) return;
    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) {
      TopToastUtil.showError(
        context: context,
        title: 'Please sign in first.',
      );
      return;
    }

    setState(() => _openingWeb = true);
    try {
      final ticketRes = await AuthService().webLoginTicket();
      final ticket = ticketRes['ticket']?.toString();
      if (ticket == null || ticket.isEmpty) {
        throw StateError('empty ticket');
      }

      final uri = Uri.parse('$appUrl/auth/app-login').replace(
        queryParameters: {
          'ticket': ticket,
          'next': '/talent-radar',
        },
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Failed to open Talent Radar. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _openingWeb = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Radar 未发布：页面写死为 Web 引导空状态，不拉取、不展示任何
    // 历史任务（含其他端创建的）。上线时从 git 历史恢复任务列表逻辑。
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double s = constraints.maxWidth / 430;
          return SafeArea(bottom: false, child: _emptyState(s));
        },
      ),
    );
  }

  // ============== 空状态（还原 _TasksPageOverlay）==============
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
          _DesktopExperienceCard(
            scale: s,
            opening: _openingWeb,
            onOpenWeb: _openTalentRadarWeb,
          ),
          SizedBox(height: 20 * s),
          _StepCard(
            scale: s,
            step: '1',
            title: 'Describe',
            subtitle: 'Describe the role in plain language.',
          ),
          SizedBox(height: 12 * s),
          _StepCard(
            scale: s,
            step: '2',
            title: 'Auto Scan',
            subtitle: 'Radar runs 24/7 across platforms.',
          ),
          SizedBox(height: 12 * s),
          _StepCard(
            scale: s,
            step: '3',
            title: 'Get Notified',
            subtitle: 'Matches delivered to your inbox daily.',
          ),
        ],
      ),
    );
  }
}

/// 桌面体验引导卡：带 ticket 打开 Web Talent Radar
class _DesktopExperienceCard extends StatelessWidget {
  const _DesktopExperienceCard({
    required this.scale,
    required this.onOpenWeb,
    this.opening = false,
  });

  final double scale;
  final VoidCallback onOpenWeb;
  final bool opening;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40 * s,
                height: 40 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD8D5CF)),
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.public_outlined,
                  size: 22 * s,
                  color: DinqTokens.textPrimary,
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get the best experience on desktop',
                      style: TextStyle(
                        fontSize: 15 * s,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: DinqTokens.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 13 * s,
                          height: 18 / 13,
                          fontWeight: FontWeight.w400,
                          color: DinqTokens.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Visit '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: opening ? null : onOpenWeb,
                              child: Text(
                                'dinq.me',
                                style: TextStyle(
                                  fontSize: 13 * s,
                                  height: 18 / 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' to access the full Talent Radar experience.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          Material(
            color: DinqTokens.textPrimary,
            borderRadius: BorderRadius.circular(12 * s),
            child: InkWell(
              onTap: opening ? null : onOpenWeb,
              borderRadius: BorderRadius.circular(12 * s),
              child: SizedBox(
                height: 48 * s,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (opening) ...[
                      SizedBox(
                        width: 16 * s,
                        height: 16 * s,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8 * s),
                    ],
                    Text(
                      'Open dinq.me',
                      style: TextStyle(
                        fontSize: 15 * s,
                        height: 20 / 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (!opening) ...[
                      SizedBox(width: 6 * s),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 18 * s,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
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
            padding: EdgeInsets.fromLTRB(
              30 * scale,
              18 * scale,
              24 * scale,
              18 * scale,
            ),
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
