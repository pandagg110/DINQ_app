import 'package:flutter/material.dart';
import '../../models/recommendation_models.dart' as rec;

/// 筛选项配置（与设计图一致：Conference / Year / Paper Level / Research Direction）
const Map<String, List<({String label, dynamic value})>> kFilterOptions = {
  'conference': [
    (label: 'CVPR', value: 'cvpr'),
    (label: 'ECCV', value: 'eccv'),
    (label: 'NeurIPS', value: 'neurips'),
    (label: 'CoRL', value: 'corl'),
    (label: 'ICLR', value: 'iclr'),
    (label: 'COLT', value: 'colt'),
    (label: 'ICML', value: 'icml'),
    (label: 'COLM', value: 'colm'),
    (label: 'ICCV', value: 'iccv'),
  ],
  'year': [
    (label: '2026', value: 2026),
    (label: '2025', value: 2025),
  ],
  'status': [
    (label: 'Best Paper', value: 'best_paper'),
    (label: 'Oral', value: 'oral'),
    (label: 'Spotlight', value: 'spotlight'),
    (label: 'Poster', value: 'poster'),
  ],
  'group': [
    (label: 'AIGC', value: 'aigc'),
    (label: 'Robot', value: 'robot'),
    (label: 'LLM', value: 'llm'),
    (label: 'CV', value: 'cv'),
    (label: 'Agent', value: 'agent'),
  ],
};

/// 未选中态边框
const Color _kFilterBorderDefault = Color(0xFFEBEBEB);
/// 选中态背景
const Color _kFilterBgSelected = Color(0xFFEFF7FF);
/// 选中态边框、文字、图标
const Color _kFilterSelectedBlue = Color(0xFF1487FA);

/// 根据 value 获取选项显示标签（与 TSX getOptionLabel 一致）
String getFilterOptionLabel(String key, dynamic value) {
  final list = kFilterOptions[key];
  if (list == null) return value.toString();
  for (final o in list) {
    if (o.value == value) return o.label;
  }
  return value.toString();
}

/// 收集所有选中的条件，用于列表页展示已选标签（与 TSX getSelectedItems 一致）
List<({String key, dynamic value, String label})> getSelectedFilterItems(rec.PaperFiltersState filters) {
  final items = <({String key, dynamic value, String label})>[];
  for (final v in filters.conference) {
    items.add((key: 'conference', value: v, label: getFilterOptionLabel('conference', v)));
  }
  for (final v in filters.year) {
    items.add((key: 'year', value: v, label: getFilterOptionLabel('year', v)));
  }
  for (final v in filters.status) {
    items.add((key: 'status', value: v, label: getFilterOptionLabel('status', v)));
  }
  for (final v in filters.group) {
    items.add((key: 'group', value: v, label: getFilterOptionLabel('group', v)));
  }
  return items;
}

/// Paper 筛选页：Conference / Year / Paper Level / Research Direction，与 PaperFilters.tsx 内容一致
class PaperFiltersPage extends StatefulWidget {
  const PaperFiltersPage({
    super.key,
    required this.initialFilters,
  });

  final rec.PaperFiltersState initialFilters;

  @override
  State<PaperFiltersPage> createState() => _PaperFiltersPageState();
}

class _PaperFiltersPageState extends State<PaperFiltersPage> {
  late rec.PaperFiltersState _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = rec.PaperFiltersState(
      conference: List.from(widget.initialFilters.conference),
      year: List.from(widget.initialFilters.year),
      status: List.from(widget.initialFilters.status),
      group: List.from(widget.initialFilters.group),
    );
  }

  void _toggleConference(String value) {
    setState(() {
      final list = List<String>.from(_localFilters.conference);
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      _localFilters = _localFilters.copyWith(conference: list);
    });
  }

  void _toggleYear(int value) {
    setState(() {
      final list = List<int>.from(_localFilters.year);
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      _localFilters = _localFilters.copyWith(year: list);
    });
  }

  void _toggleStatus(String value) {
    setState(() {
      final list = List<String>.from(_localFilters.status);
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      _localFilters = _localFilters.copyWith(status: list);
    });
  }

  void _toggleGroup(String value) {
    setState(() {
      final list = List<String>.from(_localFilters.group);
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      _localFilters = _localFilters.copyWith(group: list);
    });
  }

  void _clearAll() {
    setState(() {
      _localFilters = rec.PaperFiltersState();
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_localFilters);
  }

  int get _selectedCount =>
      _localFilters.conference.length +
      _localFilters.year.length +
      _localFilters.status.length +
      _localFilters.group.length;

  bool get _hasLocalFilters => _selectedCount > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF171717)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Filter Papers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _hasLocalFilters ? _clearAll : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _hasLocalFilters
                          ? const Color(0xFF171717)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE), // 浅蓝徽章背景
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_selectedCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FilterSection(
                    label: 'Conference',
                    options: kFilterOptions['conference']!,
                    selectedStrings: _localFilters.conference,
                    onToggleString: _toggleConference,
                  ),
                  const SizedBox(height: 24),
                  _FilterSectionYear(
                    label: 'Year',
                    options: kFilterOptions['year']!,
                    selected: _localFilters.year,
                    onToggle: _toggleYear,
                  ),
                  const SizedBox(height: 24),
                  _FilterSection(
                    label: 'Paper Level',
                    options: kFilterOptions['status']!,
                    selectedStrings: _localFilters.status,
                    onToggleString: _toggleStatus,
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    label: 'Research Direction',
                    options: kFilterOptions['group']!,
                    selectedStrings: _localFilters.group,
                    onToggleString: _toggleGroup,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF171717),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.label,
    required this.options,
    required this.selectedStrings,
    required this.onToggleString,
  });

  final String label;
  final List<({String label, dynamic value})> options;
  final List<String> selectedStrings;
  final void Function(String value) onToggleString;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final value = option.value as String;
            final isSelected = selectedStrings.contains(value);
            return _FilterChip(
              label: option.label,
              isSelected: isSelected,
              onTap: () => onToggleString(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FilterSectionYear extends StatelessWidget {
  const _FilterSectionYear({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<({String label, dynamic value})> options;
  final List<int> selected;
  final void Function(int value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final value = option.value as int;
            final isSelected = selected.contains(value);
            return _FilterChip(
              label: option.label,
              isSelected: isSelected,
              onTap: () => onToggle(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 单个筛选标签：高度固定 40，宽度随内容；gap: 10 border-radius: 50 border-width: 1 padding: 16,8,16,8
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _borderWidth = 1;
  static const double _borderRadius = 50;
  static const double _height = 40;
  static const double _gap = 10;
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(16, 8, 16, 8);
  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeInOut;
  static const Color _textUnselected = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: AnimatedContainer(
          duration: _duration,
          curve: _curve,
          height: _height,
          padding: _padding,
          decoration: BoxDecoration(
            color: isSelected ? _kFilterBgSelected : Colors.white,
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(
              color: isSelected ? _kFilterSelectedBlue : _kFilterBorderDefault,
              width: _borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: _duration,
                curve: _curve,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _textUnselected,
                ),
                child: Text(label),
              ),
              const SizedBox(width: _gap),
              TweenAnimationBuilder<double>(
                key: ValueKey(isSelected),
                tween: Tween(begin: 0, end: 1),
                duration: _duration,
                curve: _curve,
                builder: (_, t, __) {
                  final value = isSelected ? t : 1 - t;
                  final color = Color.lerp(
                    _textUnselected,
                    _kFilterSelectedBlue,
                    value,
                  )!;
                  return Icon(
                    isSelected ? Icons.close : Icons.add,
                    size: 12,
                    color: _textUnselected,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
