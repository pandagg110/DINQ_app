import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'model_channels.dart';

/// 与 TSX SearchBox ModelProviderIcon + 模型下拉 / BottomSheet 对齐。
class ModelProviderSelector extends StatefulWidget {
  const ModelProviderSelector({
    super.key,
    required this.options,
    required this.modelProvider,
    required this.onModelProviderChange,
    this.dropdownPosition = 'up',
    this.isMobile = true,
  });

  final List<ModelOption> options;
  final String modelProvider;
  final ValueChanged<String> onModelProviderChange;
  final String dropdownPosition;
  final bool isMobile;

  @override
  State<ModelProviderSelector> createState() => _ModelProviderSelectorState();
}

class _ModelProviderSelectorState extends State<ModelProviderSelector> {
  var _menuOpen = false;

  ModelOption? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.modelProvider) return option;
    }
    return widget.options.isNotEmpty ? widget.options.first : null;
  }

  String get _selectedLabel =>
      _selected?.displayLabel ?? _selected?.label ?? widget.modelProvider;

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: _menuOpen ? const Color(0xFFF5F4F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              if (widget.isMobile) {
                _showMobileSheet(context);
              } else {
                setState(() => _menuOpen = !_menuOpen);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 32,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModelProviderIcon(
                      iconAsset: _selected?.iconAsset,
                      label: _selected?.label,
                    ),
                    if (!widget.isMobile) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: Text(
                          _selectedLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF6B6862),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        widget.dropdownPosition == 'up'
                            ? (_menuOpen
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up)
                            : (_menuOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down),
                        size: 14,
                        color: const Color(0xFF6B6862),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!widget.isMobile && _menuOpen)
          Positioned(
            right: 0,
            bottom: widget.dropdownPosition == 'up' ? 38 : null,
            top: widget.dropdownPosition == 'down' ? 38 : null,
            child: ModelProviderMenu(
              visible: true,
              options: widget.options,
              selected: widget.modelProvider,
              onSelect: (value) {
                widget.onModelProviderChange(value);
                setState(() => _menuOpen = false);
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showMobileSheet(BuildContext context) async {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight =
        72.0 + widget.options.length * 52.0 + bottomInset + 24;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2826),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B6862)),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = option.value == widget.modelProvider;
                    return Material(
                      color: isSelected
                          ? const Color(0xFFF5F4F0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(option.value),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              _ModelProviderIcon(
                                iconAsset: option.iconAsset,
                                label: option.label,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.displayLabel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? const Color(0xFF2A2826)
                                        : const Color(0xFF6B6862),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Color(0xFF2A2826),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) widget.onModelProviderChange(selected);
  }
}

/// 桌面端模型菜单（与 ToolsMenu / menuStyles 对齐）。
class ModelProviderMenu extends StatelessWidget {
  const ModelProviderMenu({
    super.key,
    required this.visible,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final bool visible;
  final List<ModelOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD5D3CE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              Material(
                color: option.value == selected
                    ? const Color(0xFFF5F4F0)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onSelect(option.value),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 36,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _ModelProviderIcon(
                            iconAsset: option.iconAsset,
                            label: option.label,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option.displayLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: option.value == selected
                                    ? const Color(0xFF2A2826)
                                    : const Color(0xFF6B6862),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (option.value == selected)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF2A2826),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelProviderIcon extends StatelessWidget {
  const _ModelProviderIcon({
    this.iconAsset,
    this.label,
    this.size = 16,
  });

  final String? iconAsset;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconAsset != null) {
      return Opacity(
        opacity: 0.8,
        child: SvgPicture.asset(
          iconAsset!,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(Color(0xFF6B6862), BlendMode.srcIn),
        ),
      );
    }
    final trimmed = (label ?? '?').trim();
    final initial = trimmed.isNotEmpty ? trimmed[0] : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E3DE),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.56,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B6862),
        ),
      ),
    );
  }
}
