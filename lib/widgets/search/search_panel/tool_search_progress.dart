import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// 与 TSX `ToolSearchProgress.tsx` 对齐；阶段图标来自 Lucide（iconify 导出）。
abstract final class ToolSearchProgressAssets {
  ToolSearchProgressAssets._();

  static const _base = 'assets/icons/search/progress/';
  static const checkCircle = '${_base}check-circle.svg';
  static const chevronDown = '${_base}chevron-down.svg';

  static String? lucideAsset(String? iconClass) {
    if (iconClass == null || !iconClass.startsWith('i-lucide-')) return null;
    final name = iconClass.replaceFirst('i-lucide-', '');
    return '$_base$name.svg';
  }
}

/// 与 TSX `ToolSearchProgress.tsx` 对齐。
class ToolSearchProgress extends StatefulWidget {
  const ToolSearchProgress({
    super.key,
    required this.phases,
    required this.isFinished,
    required this.finishedLabel,
  });

  final List<ToolSearchPhase> phases;
  final bool isFinished;
  final String finishedLabel;

  @override
  State<ToolSearchProgress> createState() => _ToolSearchProgressState();
}

class _ToolSearchProgressState extends State<ToolSearchProgress> {
  bool _expanded = false;
  bool _prevFinished = false;
  int _spinnerFrame = 0;
  Timer? _spinnerTimer;

  static const _brailleFrames = ['⣷', '⣯', '⣟', '⡿', '⢿', '⣻', '⣽', '⣾'];

  @override
  void initState() {
    super.initState();
    _prevFinished = widget.isFinished;
    _startSpinner();
  }

  @override
  void didUpdateWidget(covariant ToolSearchProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFinished && !_prevFinished) {
      _expanded = false;
    }
    _prevFinished = widget.isFinished;
    if (widget.isFinished) {
      _spinnerTimer?.cancel();
    } else {
      _startSpinner();
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _startSpinner() {
    _spinnerTimer?.cancel();
    if (widget.isFinished) return;
    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _spinnerFrame = (_spinnerFrame + 1) % _brailleFrames.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phases.isEmpty && widget.isFinished) {
      return const SizedBox.shrink();
    }

    final canExpand = widget.phases.isNotEmpty;
    ToolSearchPhase? activePhase;
    for (final phase in widget.phases) {
      if (phase.status == 'active') {
        activePhase = phase;
        break;
      }
    }
    final rawLabel = widget.isFinished
        ? (widget.finishedLabel.isNotEmpty ? widget.finishedLabel : 'Done')
        : (activePhase?.label ?? 'Preparing');
    final summaryText = widget.isFinished
        ? rawLabel
        : rawLabel.replaceAll(RegExp(r'\.{2,}$'), '');
    final isWaiting = activePhase?.waiting ?? false;
    final showShimmer = !widget.isFinished && !isWaiting;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE7E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBar(
              canExpand: canExpand,
              expanded: _expanded,
              onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
              leading: _HeaderLeading(
                isFinished: widget.isFinished,
                isWaiting: isWaiting,
                icon: activePhase?.icon,
                spinnerFrame: _spinnerFrame,
              ),
              label: summaryText,
              showShimmer: showShimmer,
              showDots: !widget.isFinished && !isWaiting,
              isFinished: widget.isFinished,
              isWaiting: isWaiting,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topLeft,
              child: _expanded && canExpand
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(36, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < widget.phases.length; i++)
                            _PhaseRow(
                              phase: widget.phases[i],
                              isLast: i == widget.phases.length - 1,
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.canExpand,
    required this.expanded,
    required this.onTap,
    required this.leading,
    required this.label,
    required this.showShimmer,
    required this.showDots,
    required this.isFinished,
    required this.isWaiting,
  });

  final bool canExpand;
  final bool expanded;
  final VoidCallback? onTap;
  final Widget leading;
  final String label;
  final bool showShimmer;
  final bool showDots;
  final bool isFinished;
  final bool isWaiting;

  static const _activeColor = Color(0xFF6B6862);
  static const _mutedColor = Color(0xFF9E9A94);

  @override
  Widget build(BuildContext context) {
    final titleColor = isFinished || isWaiting ? _mutedColor : _activeColor;

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Center(child: leading),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: showShimmer
                          ? _ShimmerText(
                              text: label,
                              style: const TextStyle(fontSize: 14, color: _activeColor),
                            )
                          : Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: titleColor),
                            ),
                    ),
                    if (showDots) const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: _PulsingDots(),
                    ),
                  ],
                ),
              ),
              if (canExpand)
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    ToolSearchProgressAssets.chevronDown,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      _mutedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (canExpand) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color(0xFFF5F4F0),
          highlightColor: const Color(0xFFF5F4F0),
          splashColor: const Color(0xFFF5F4F0),
          child: content,
        ),
      );
    }
    return content;
  }
}

class _HeaderLeading extends StatelessWidget {
  const _HeaderLeading({
    required this.isFinished,
    required this.isWaiting,
    required this.icon,
    required this.spinnerFrame,
  });

  final bool isFinished;
  final bool isWaiting;
  final String? icon;
  final int spinnerFrame;

  static const _brailleFrames = ['⣷', '⣯', '⣟', '⡿', '⢿', '⣻', '⣽', '⣾'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: isFinished
            ? const _ProgressIcon(size: 14)
            : isWaiting && icon != null
                ? _ProgressIcon(icon: icon, size: 14)
                : Transform.translate(
                    offset: const Offset(0, -1),
                    child: Text(
                      _brailleFrames[spinnerFrame % _brailleFrames.length],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Color(0xFF9E9A94),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.phase, required this.isLast});

  final ToolSearchPhase phase;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isActive = phase.status == 'active';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: [
          if (!isLast)
            Positioned(
              left: -15,
              top: 16,
              bottom: -12,
              child: Container(
                width: 1,
                color: const Color(0xFFEAE7E0),
              ),
            ),
          Positioned(
            left: -24,
            top: 0,
            child: SizedBox(
              width: 20,
              height: 16,
              child: Center(
                child: phase.icon != null
                    ? _ProgressIcon(icon: phase.icon, size: 14)
                    : const _ProgressIcon(size: 14),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              isActive && !phase.waiting
                  ? _ShimmerText(
                      text: phase.label,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: Color(0xFF6B6862),
                      ),
                    )
                  : Text(
                      phase.label,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: isActive ? const Color(0xFF6B6862) : const Color(0xFF9E9A94),
                      ),
                    ),
              if (phase.sources != null && phase.sources!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _SourcesList(sources: phase.sources!),
                ),
              if (phase.children != null && phase.children!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final child in phase.children!) _ChildChip(child: child),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourcesList extends StatelessWidget {
  const _SourcesList({required this.sources});

  final List<ToolSearchPhaseSource> sources;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAE7E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < sources.length; i++)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openUrl(sources[i].url),
                  hoverColor: const Color(0xFFF5F4F0),
                  highlightColor: const Color(0xFFF5F4F0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: i < sources.length - 1
                          ? const Border(bottom: BorderSide(color: Color(0xFFEAE7E0)))
                          : null,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            'https://icons.duckduckgo.com/ip3/${sources[i].domain}.ico',
                            width: 14,
                            height: 14,
                            errorBuilder: (_, e, s) => const SizedBox(width: 14, height: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sources[i].domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF716E6A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({required this.child});

  final ToolSearchPhaseChild child;

  @override
  Widget build(BuildContext context) {
    final isDone = child.status == 'done';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: Center(
            child: isDone
                ? SvgPicture.asset(
                    ToolSearchProgressAssets.checkCircle,
                    width: 10,
                    height: 10,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF9E9A94),
                      BlendMode.srcIn,
                    ),
                  )
                : Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6D3CD),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          child.label,
          style: TextStyle(
            fontSize: 11,
            color: isDone ? const Color(0xFF9E9A94) : const Color(0xFFD6D3CD),
          ),
        ),
      ],
    );
  }
}

class _ProgressIcon extends StatelessWidget {
  const _ProgressIcon({this.icon, this.size = 14});

  final String? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = ToolSearchProgressAssets.lucideAsset(icon) ?? ToolSearchProgressAssets.checkCircle;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(
        Color(0xFF9E9A94),
        BlendMode.srcIn,
      ),
    );
  }
}

class _ShimmerText extends StatefulWidget {
  const _ShimmerText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final offset = bounds.width * (1 - _controller.value * 2);
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF6B6862),
                Color(0xFF6B6862),
                Color(0xFFC4C1BB),
                Color(0xFF6B6862),
                Color(0xFF6B6862),
              ],
              stops: [0, 0.35, 0.5, 0.65, 1],
            ).createShader(Rect.fromLTWH(offset, 0, bounds.width * 2, bounds.height));
          },
          child: Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOpacity(double t, double delay) {
    final phase = (t + delay) % 1.0;
    if (phase < 0.32) return phase / 0.32;
    if (phase < 0.64) return 1 - (phase - 0.32) / 0.32;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Opacity(
                  opacity: _dotOpacity(_controller.value, i * 0.14),
                  child: const Text(
                    '.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B6862), height: 1),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ToolSearchPhase {
  const ToolSearchPhase({
    required this.key,
    required this.label,
    required this.status,
    this.icon,
    this.waiting = false,
    this.sources,
    this.children,
  });

  final String key;
  final String label;
  final String status;
  final String? icon;
  final bool waiting;
  final List<ToolSearchPhaseSource>? sources;
  final List<ToolSearchPhaseChild>? children;
}

class ToolSearchPhaseSource {
  const ToolSearchPhaseSource({required this.url, required this.domain});

  final String url;
  final String domain;
}

class ToolSearchPhaseChild {
  const ToolSearchPhaseChild({
    required this.key,
    required this.label,
    required this.status,
  });

  final String key;
  final String label;
  final String status;
}

List<ToolSearchPhase> buildCitationPhases(String? currentPhase, bool isFinished) {
  if (currentPhase == null && !isFinished) return [];
  return [
    ToolSearchPhase(
      key: 'searching',
      label: isFinished ? 'Citations found' : 'Searching citations',
      icon: 'i-lucide-book-open',
      status: isFinished ? 'done' : 'active',
    ),
  ];
}
