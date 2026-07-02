import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/prompts.dart';
import '../../stores/search_store.dart';

const int displayCount = 4;

class PromptTemplateGridWidget extends StatefulWidget {
  const PromptTemplateGridWidget({
    super.key,
    this.onQueryFromPapers,
    this.onPromptSelected,
  });

  /// Papers 页通过 Find Authors 返回的搜索文案，用于自动发起搜索
  final ValueChanged<String>? onQueryFromPapers;
  final ValueChanged<String>? onPromptSelected;

  @override
  State<PromptTemplateGridWidget> createState() =>
      _PromptTemplateGridWidgetState();
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
    if (widget.onPromptSelected != null) {
      widget.onPromptSelected!(content);
      return;
    }
    final searchStore = context.read<SearchStore>();
    searchStore.fillSearchBox(content);
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedPrompts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 单列垂直排列，只显示前3条 prompts
    const spacing = 10.0;
    final displayCount = _displayedPrompts.length.clamp(0, 3);

    return Container(
      constraints: const BoxConstraints(maxWidth: 768),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Prompt Examples',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9B93)),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _isShuffling ? null : _handleShuffle,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _isShuffling ? 0.5 : 0,
                    child: const Icon(
                      Icons.refresh,
                      size: 15,
                      color: Color(0xFF9E9B93),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(displayCount, (index) {
              final prompt = _displayedPrompts[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < displayCount - 1 ? spacing : 0,
                ),
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
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  const _PromptCard({required this.prompt, required this.onTap});

  final PromptTemplate prompt;
  final VoidCallback onTap;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF7F6F2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD5D3CE), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.prompt.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFFB8B4AD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
