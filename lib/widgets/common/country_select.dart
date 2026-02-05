import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/country_data.dart';
import '../../utils/color_util.dart';

/// 国家选择组件 - 支持搜索过滤的下拉选择器
class CountrySelect extends StatefulWidget {
  final String? selectedCountry;
  final ValueChanged<String> onCountryChanged;
  final bool required;
  final String label;

  const CountrySelect({
    super.key,
    this.selectedCountry,
    required this.onCountryChanged,
    this.required = false,
    this.label = 'Country/Region',
  });

  @override
  State<CountrySelect> createState() => _CountrySelectState();
}

class _CountrySelectState extends State<CountrySelect> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<CountryInfo> _filteredCountries = countryList;
  bool _isDropdownOpen = false;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCountry != null && widget.selectedCountry!.isNotEmpty) {
      _inputController.text = widget.selectedCountry!;
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CountrySelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCountry != oldWidget.selectedCountry && !_isDropdownOpen) {
      _inputController.text = widget.selectedCountry ?? '';
    }
  }

  @override
  void dispose() {
    // 先移除 overlay，不调用 setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    _inputController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // 延迟关闭，允许点击下拉菜单选项
      Future.delayed(const Duration(milliseconds: 150), () {
        // 检查 widget 是否仍然挂载
        if (!mounted) return;
        if (!_focusNode.hasFocus) {
          _handleBlur();
        }
      });
    }
  }

  void _handleBlur() {
    if (!mounted) return;
    if (_isDropdownOpen) {
      // 检查输入的值是否是有效的国家名
      final exactMatch = countryList.where(
        (country) => country.name.toLowerCase() == _inputController.text.toLowerCase(),
      ).firstOrNull;

      if (exactMatch != null) {
        _selectCountry(exactMatch);
      } else {
        // 恢复到之前选择的值
        _inputController.text = widget.selectedCountry ?? '';
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    if (_isDropdownOpen || !mounted) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
      _filteredCountries = countryList;
      _highlightedIndex = -1;
    });

    // 选中输入框中的文本
    _inputController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _inputController.text.length,
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
        _filteredCountries = countryList;
        _highlightedIndex = -1;
      });
    }
  }

  void _onInputChanged(String value) {
    if (!mounted) return;
    final filtered = countryList
        .where((country) => country.name.toLowerCase().contains(value.toLowerCase()))
        .toList();

    setState(() {
      _filteredCountries = filtered;
      _highlightedIndex = -1;
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _selectCountry(CountryInfo country) {
    if (!mounted) return;
    widget.onCountryChanged(country.name);
    _inputController.text = country.name;
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _inputController.text = widget.selectedCountry ?? '';
      _removeOverlay();
      _focusNode.unfocus();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredCountries.length) {
        _selectCountry(_filteredCountries[_highlightedIndex]);
      } else if (_filteredCountries.length == 1) {
        _selectCountry(_filteredCountries[0]);
      } else {
        // 尝试精确匹配
        final exactMatch = _filteredCountries.where(
          (country) => country.name.toLowerCase() == _inputController.text.toLowerCase(),
        ).firstOrNull;
        if (exactMatch != null) {
          _selectCountry(exactMatch);
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredCountries.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % _filteredCountries.length;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredCountries.isNotEmpty) {
        setState(() {
          _highlightedIndex = _highlightedIndex <= 0
              ? _filteredCountries.length - 1
              : _highlightedIndex - 1;
        });
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorUtil.textColor),
              ),
              child: _filteredCountries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No countries found matching "${_inputController.text}"',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorUtil.sub1TextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected = country.name == widget.selectedCountry;
                        final isHighlighted = index == _highlightedIndex;

                        return InkWell(
                          onTap: () => _selectCountry(country),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? const Color(0xFFF9F9F9)
                                  : isSelected
                                      ? const Color(0x0D303030)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: ColorUtil.textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: ColorUtil.textColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: ColorUtil.textColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tomato Grotesk',
              ),
            ),
            if (widget.required)
              const Text(' *', style: TextStyle(color: Color(0xFFC81E1D))),
          ],
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyEvent,
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                onChanged: _onInputChanged,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtil.textColor,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Select country or region',
                  hintStyle: const TextStyle(
                    color: Color(0x66303030),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: AnimatedRotation(
                    turns: _isDropdownOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: ColorUtil.textColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
