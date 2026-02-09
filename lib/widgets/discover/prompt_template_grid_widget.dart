import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/prompts.dart';
import '../../stores/search_store.dart';

const int displayCount = 4;

class PromptTemplateGridWidget extends StatefulWidget {
  const PromptTemplateGridWidget({super.key});

  @override
  State<PromptTemplateGridWidget> createState() => _PromptTemplateGridWidgetState();
}

class _PromptTemplateGridWidgetState extends State<PromptTemplateGridWidget>
    with SingleTickerProviderStateMixin {
  List<PromptTemplate> _displayedPrompts = [];
  bool _isShuffling = false;
  int _shuffleKey = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward(); // 初始状态为显示
    _displayedPrompts = _getRandomPrompts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<PromptTemplate> _getRandomPrompts() {
    final shuffled = List<PromptTemplate>.from(promptTemplates);
    shuffled.shuffle(Random());
    return shuffled.take(displayCount).toList();
  }

  void _handleShuffle() {
    if (_isShuffling) return;
    setState(() {
      _isShuffling = true;
    });

    // 先淡出
    _animationController.reverse().then((_) {
      setState(() {
        _shuffleKey += 1;
        _displayedPrompts = _getRandomPrompts();
      });
      // 淡入
      _animationController.forward().then((_) {
        setState(() {
          _isShuffling = false;
        });
      });
    });
  }

  void _handleFill(String content) {
    final searchStore = context.read<SearchStore>();
    searchStore.fillSearchBox(content);
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedPrompts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 仅移动端：2 列，最多显示 2 个
    const crossAxisCount = 2;
    const spacing = 12.0;
    final count = _displayedPrompts.length.clamp(0, 2);

    return Container(
      constraints: const BoxConstraints(maxWidth: 768),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prompt examples',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              TextButton(
                onPressed: _isShuffling ? null : _handleShuffle,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isShuffling)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
                        ),
                      )
                    else
                      const Icon(
                        Icons.refresh,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    const SizedBox(width: 6),
                    const Text(
                      'Shuffle',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(count, (index) {
                  final prompt = _displayedPrompts[index];
                  return SizedBox(
                    width: itemWidth,
                    child: FadeTransition(
                      key: ValueKey('${_shuffleKey}_${prompt.id}'),
                      opacity: _animationController,
                      child: _PromptCard(
                        prompt: prompt,
                        onTap: () => _handleFill(prompt.content),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  const _PromptCard({
    required this.prompt,
    required this.onTap,
  });

  final PromptTemplate prompt;
  final VoidCallback onTap;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            border: Border.all(
              color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Title（右侧留 16 避免与箭头图标重叠）
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  widget.prompt.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isHovered ? const Color(0xFF171717) : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Arrow icon
              Positioned(
                right: 0,
                bottom: 0,
                child: Transform.rotate(
                  angle: -pi / 4, // 45° 朝向左上角
                  child: Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
