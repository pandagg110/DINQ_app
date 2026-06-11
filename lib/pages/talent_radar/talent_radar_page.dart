import 'package:flutter/material.dart';

import '../../theme/dinq_icons.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/dinq_svg_icon.dart';

/// Talent Radar Tab（持续找人）空状态。
/// 1:1 还原 `my_first_app` 的 `_TasksPageOverlay` 空状态：
/// 产品说明 pill + 标语 + 创建入口 + 三步引导。
/// 命名按《DINQ Page 命名口径》统一为 Talent Radar。
class TalentRadarPage extends StatelessWidget {
  const TalentRadarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double s = constraints.maxWidth / 430;
          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 104 * s),
              child: Column(
                children: [
                  _PageHeaderTitle(scale: s, title: 'Talent Radar'),
                  SizedBox(height: 34 * s),
                  // 产品说明 pill
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
                  // 创建入口
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // TODO(radar-create): 创建 Radar 流程（设计待补）
                    },
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
                          DinqSvgIcon(
                            assetName: DinqIcons.plus,
                            size: 18 * s,
                            color: DinqTokens.bgCard,
                          ),
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
            ),
          );
        },
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
