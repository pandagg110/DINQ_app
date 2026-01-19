import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/landing.dart';
import '../common/lottie_view.dart';
import '../../utils/asset_path.dart';

class TabsMedia extends StatelessWidget {
  const TabsMedia({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<TabContent> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = items[selectedIndex];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  left: tabWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isActive = index == selectedIndex;
                    return Expanded(
                      child: InkWell(
                        onTap: () => onChanged(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isActive ? Colors.white : const Color(0xFF303030),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF171717)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _TabText(key: ValueKey(active.key), content: active),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _TabMedia(key: ValueKey(active.key), content: active),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabText extends StatelessWidget {
  const _TabText({super.key, required this.content});

  final TabContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.label,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 16),
        ...content.emphasisCopy.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                children: line
                    .map(
                      (segment) => TextSpan(
                        text: segment.text,
                        style: TextStyle(
                          color: _hexToColor(segment.color),
                          fontWeight: segment.color == '#171717' ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabMedia extends StatelessWidget {
  const _TabMedia({super.key, required this.content});

  final TabContent content;

  @override
  Widget build(BuildContext context) {
    if (content.animationPath != null) {
      return LottieView(asset: content.animationPath!.replaceFirst('/', ''));
    }
    if (content.imagePath != null) {
      final path = content.imagePath!;
      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(assetPath(path), fit: BoxFit.contain);
      }
      return Image.asset(
        assetPath(path),
        fit: BoxFit.contain,
      );
    }
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4D4D4)),
      ),
      child: const Text('Placeholder'),
    );
  }
}

Color _hexToColor(String hex) {
  final value = hex.replaceAll('#', '');
  if (value.length == 6) {
    return Color(int.parse('FF$value', radix: 16));
  }
  if (value.length == 8) {
    return Color(int.parse(value, radix: 16));
  }
  return const Color(0xFF171717);
}

