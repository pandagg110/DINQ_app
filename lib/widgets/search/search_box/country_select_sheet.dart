import 'package:flutter/material.dart';
import 'search_box_types.dart';

const _kCountryOptions = [
  'USA',
  'Canada',
  'China',
  'Hong Kong',
  'Macao',
  'Taiwan',
  'UK',
  'Germany',
  'Australia',
  'Singapore',
  'Japan',
  'France',
  'Netherlands',
];

/// 与 TSX CountrySelectModal 对齐
class CountrySelectSheet extends StatefulWidget {
  const CountrySelectSheet({
    super.key,
    required this.initialSelected,
    required this.onConfirm,
  });

  final List<String> initialSelected;
  final ValueChanged<List<String>> onConfirm;

  static Future<void> show(
    BuildContext context, {
    required List<String> initialSelected,
    required ValueChanged<List<String>> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountrySelectSheet(
        initialSelected: initialSelected,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CountrySelectSheet> createState() => _CountrySelectSheetState();
}

class _CountrySelectSheetState extends State<CountrySelectSheet> {
  late List<String> _tempCountries;

  @override
  void initState() {
    super.initState();
    _tempCountries = List<String>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Countries',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kCountryOptions.map((country) {
                    final isSelected = _tempCountries.contains(country);
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: Material(
                        color: isSelected
                            ? const Color(0xFFE5E5E5)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _tempCountries.remove(country);
                              } else {
                                _tempCountries.add(country);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    country,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF171717),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_tempCountries);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
