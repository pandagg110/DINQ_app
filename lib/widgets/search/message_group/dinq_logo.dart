import 'package:dinq_app/widgets/common/asset_icon.dart';
import 'package:flutter/material.dart';

const Duration dinqBreathingLogoDuration = Duration(milliseconds: 4000);

/// 与 TSX 一致的文案循环（按 clickCount 取 phraseIndex = (count % 8) ~/ 2）
const List<String> _dinqPhrases = [
  'Who are you looking for?',
  'Still searching? I got you.',
  'Okay okay, I\'m on it!',
  'Chill, I know everyone.',
];

/// 呼吸动画 Logo（与 TSX BreathingLogo 对应）
class BreathingLogo extends StatelessWidget {
  const BreathingLogo({super.key, this.size = 24, required this.animation});

  final double size;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final scale = _interpolateKeyframes(
          progress,
          values: const [1, 1.15, 0.9, 1.15, 0.9, 1],
        );
        final turns = _interpolateKeyframes(
          progress,
          values: const [0, 0, 0, 0, 0, 1],
        );
        return Transform.rotate(
          angle: turns * 2 * 3.14159265359,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: AssetIcon(asset: 'logo/dinq-black.svg', size: size),
    );
  }

  double _interpolateKeyframes(
    double progress, {
    required List<double> values,
  }) {
    const times = [0, 0.2, 0.4, 0.6, 0.8, 1.0];
    final clamped = progress.clamp(0.0, 1.0);
    for (var i = 0; i < times.length - 1; i++) {
      final start = times[i];
      final end = times[i + 1];
      if (clamped >= start && clamped <= end) {
        final eased = Curves.easeInOut.transform(
          (clamped - start) / (end - start),
        );
        return values[i] + (values[i + 1] - values[i]) * eased;
      }
    }
    return values.last;
  }
}

/// 与 TSX DinqLogoButton 对齐：点击 360° 旋转（0.8s）、2s 内防连点、tooltip 文案循环、isLoading/foundMoreCount 状态
class DinqLogoButton extends StatefulWidget {
  const DinqLogoButton({
    super.key,
    this.size = 24,
    this.isLoading = false,
    this.foundMoreCount,
    this.onTap,
  });

  final double size;
  final bool isLoading;
  final int? foundMoreCount;
  final VoidCallback? onTap;

  @override
  State<DinqLogoButton> createState() => _DinqLogoButtonState();
}

class _DinqLogoButtonState extends State<DinqLogoButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotation;
  late AnimationController _breathingController;
  int _clickCount = 0;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOutBack),
    );
    _rotationController.addStatusListener(_onRotationStatus);
    _breathingController = AnimationController(
      vsync: this,
      duration: dinqBreathingLogoDuration,
    );
    if (widget.isLoading) {
      _breathingController.repeat();
    }
  }

  void _onRotationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _rotationController.reset();
      setState(() => _isRotating = false);
    });
  }

  @override
  void didUpdateWidget(DinqLogoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_breathingController.isAnimating) {
      _breathingController.repeat();
    } else if (!widget.isLoading && _breathingController.isAnimating) {
      _breathingController.stop();
      _breathingController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.removeStatusListener(_onRotationStatus);
    _rotationController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  String _getPhrase() {
    if (widget.foundMoreCount != null) {
      return 'Found ${widget.foundMoreCount} more!';
    }
    if (widget.isLoading) {
      return 'DINQ is thinking...';
    }
    final index = (_clickCount % 8) ~/ 2;
    return _dinqPhrases[index.clamp(0, _dinqPhrases.length - 1)];
  }

  void _handleTap() {
    if (widget.isLoading || widget.foundMoreCount != null || _isRotating) {
      return;
    }
    setState(() {
      _clickCount++;
      _isRotating = true;
    });
    _rotationController.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // isLoading：仅显示呼吸 Logo + tooltip
    if (widget.isLoading) {
      return Tooltip(
        message: _getPhrase(),
        child: BreathingLogo(
          size: widget.size,
          animation: _breathingController,
        ),
      );
    }
    // foundMoreCount：静态 Logo + tooltip
    if (widget.foundMoreCount != null) {
      return Tooltip(
        message: _getPhrase(),
        child: AssetIcon(asset: 'logo/dinq-black.svg', size: widget.size),
      );
    }
    // 默认：可点击 + 旋转动画 + tooltip 文案循环
    final logo = AnimatedBuilder(
      animation: _rotation,
      builder: (context, _) {
        return Transform.rotate(
          angle: _rotation.value * 2 * 3.14159265359,
          child: AssetIcon(asset: 'logo/dinq-black.svg', size: widget.size),
        );
      },
    );
    return Tooltip(
      message: _getPhrase(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(padding: const EdgeInsets.all(4), child: logo),
        ),
      ),
    );
  }
}
