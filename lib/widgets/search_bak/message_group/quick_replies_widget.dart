import 'package:flutter/material.dart';

/// 与 TSX QuickReplies 对应
class QuickRepliesWidget extends StatelessWidget {
  const QuickRepliesWidget({
    super.key,
    required this.options,
    required this.onSelect,
  });

  final List<String> options;
  final ValueChanged<String> onSelect;

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    onSelect(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    if (options.length == 2) {
      final primary = options[0];
      final secondary = options[1];
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _primaryButton(primary),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _submit(secondary),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA5A39E),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      secondary,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                _primaryButton(primary),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: () => _submit(secondary),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA5A39E),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    secondary,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => _submit(opt),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2A2826),
                side: const BorderSide(color: Color(0xFFE5E3DE)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                opt,
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton(
      onPressed: () => _submit(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A2826),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.subdirectory_arrow_left, size: 14),
        ],
      ),
    );
  }
}
