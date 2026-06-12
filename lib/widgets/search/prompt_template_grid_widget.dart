import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/prompts.dart';
import '../../stores/search_store.dart';
import '../../pages/discover/recommended_papers_page.dart';

const int displayCount = 4;

class PromptTemplateGridWidget extends StatefulWidget {
  const PromptTemplateGridWidget({super.key, this.onQueryFromPapers});

  /// Papers 页通过 Find Authors 返回的搜索文案，用于自动发起搜索
  final ValueChanged<String>? onQueryFromPapers;

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
    final searchStore = context.read<SearchStore>();
    searchStore.fillSearchBox(content);
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedPrompts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 单列垂直排列，只显示前3条 prompts
    const spacing = 12.0;
    final displayCount = _displayedPrompts.length.clamp(0, 3);

    return Container(
      constraints: const BoxConstraints(maxWidth: 768),
      width: double.infinity,
      // margin: const EdgeInsets.only(top: 24),
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured prompt card with Explore button
          // _FeaturedPromptCard(
          //   title: 'Find Talent in Research',
          //   description: 'Discover top researchers',
          //   onTap: () {
          //     Navigator.of(context).push<Object?>(
          //       MaterialPageRoute<Object?>(
          //         builder: (_) => const RecommendedPapersPage(),
          //       ),
          //     ).then((result) {
          //       if (result != null && result is String) {
          //         widget.onQueryFromPapers?.call(result);
          //       }
          //     });
          //   },
          // ),
          // const SizedBox(height: 12),
          Column(
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // 更大的圆角，pill形状
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          widget.prompt.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF171717),
            height: 1.4,
          ),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _FeaturedPromptCard extends StatelessWidget {
  const _FeaturedPromptCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side: Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171717),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side: Explore button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Explore',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
