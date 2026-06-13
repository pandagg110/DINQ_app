import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';
import '../../services/upload_service.dart';

// Placeholder 常量
const List<String> globalPlaceholders = [
  'Search millions of AI talents worldwide…',
  'Find my Alec Radford',
  'Find my Jianlin Su',
  'Find my Ilya Sutskever',
  'Find my Sam Gao',
];

const List<String> dinqPlaceholders = [
  'Search verified experts on DINQ Fellows…',
  'Find my Alec Radford',
  'Find my Jianlin Su',
  'Find my Ilya Sutskever',
  'Find my Sam Gao',
];

const List<String> advisorPlaceholders = [
  'Describe your ideal advisor, e.g. research interests, mentoring style...',
  'Looking for a professor who specializes in NLP and has industry experience',
  'I prefer advisors who encourage independent research and collaboration',
  'Seeking someone with strong publication record in computer vision',
];

const double minHeight = 24.0;
const double maxHeight = 240.0;

/// find-advisor 区域约占用高度（Resume + Countries 等），用于计算输入区 maxHeight
const double _kAdvisorSectionApproxHeight = 200.0;
const int maxLength = 2000;
const int showLimitThreshold = 1800;

const List<String> _kCountryOptions = [
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

/// 虚线圆角矩形边框（用于 Resume 上传区域）
class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1,
    this.borderRadius = 8,
    this.dashWidth = 4,
    this.dashSpace = 3,
  });

  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 国家选择底部弹窗（参考 CountrySelectModal.tsx）
class _CountrySelectBottomSheet extends StatefulWidget {
  const _CountrySelectBottomSheet({
    required this.initialSelected,
    required this.onConfirm,
    required this.onCancel,
  });

  final List<String> initialSelected;
  final void Function(List<String> countries) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_CountrySelectBottomSheet> createState() =>
      _CountrySelectBottomSheetState();
}

class _CountrySelectBottomSheetState extends State<_CountrySelectBottomSheet> {
  late List<String> _tempCountries;

  @override
  void initState() {
    super.initState();
    _tempCountries = List<String>.from(widget.initialSelected);
  }

  void _toggleCountry(String country) {
    setState(() {
      if (_tempCountries.contains(country)) {
        _tempCountries.remove(country);
      } else {
        _tempCountries.add(country);
      }
    });
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
            Text(
              'Countries',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _kCountryOptions.map((country) {
                        final isSelected = _tempCountries.contains(country);
                        return SizedBox(
                          width: itemWidth,
                          child: Material(
                            color: isSelected
                                ? const Color(0xFFE5E5E5)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => _toggleCountry(country),
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
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Color(0xFF171717),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: Color(0xFF171717)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: const Color(0xFF171717),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onConfirm(_tempCountries),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

class AdvisorFormData {
  AdvisorFormData({
    required this.resumeUrl,
    this.resumeName,
    required this.additionalInfo,
    required this.countries,
    required this.maxAdvisors,
  });

  final String resumeUrl;
  final String? resumeName;
  final String additionalInfo;
  final List<String> countries;
  final int maxAdvisors;
}

class SearchBoxWidget extends StatefulWidget {
  const SearchBoxWidget({
    super.key,
    required this.onSearch,
    this.onStop,
    this.loading = false,
    this.talentMode = 'global',
    this.deepSearchMode = false,
    this.onTalentModeChange,
    this.onDinqSearchSubmit,
    this.onAdvisorSearch,
    this.advisorLoading = false,
    this.onActiveToolChange,
    this.dropdownPosition = 'down',
    this.fullWidth = true,
    this.variant = 'glass',
    this.onChanged,
  });

  final void Function({
    required String query,
    bool simple,
    String? attachmentUrl,
    String? attachmentName,
  }) onSearch;
  final VoidCallback? onStop;
  final bool loading;
  final String talentMode; // 'global' or 'dinq'
  /// 有消息时切换为 Deep Search 输入模式（Ask placeholder、隐藏 talent toggle）
  final bool deepSearchMode;
  /// 输入内容变化时回调（便于父组件监听输入）
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onTalentModeChange;
  final ValueChanged<String>? onDinqSearchSubmit;
  final ValueChanged<AdvisorFormData>? onAdvisorSearch;
  final bool advisorLoading;
  final ValueChanged<String?>? onActiveToolChange;
  final String dropdownPosition; // 'up' or 'down'
  final bool fullWidth;
  final String variant; // 'default' or 'glass'

  @override
  State<SearchBoxWidget> createState() => _SearchBoxWidgetState();
}

class _SearchBoxWidgetState extends State<SearchBoxWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;
  bool _isFocused = false;
  double _textFieldHeight = minHeight;
  bool _showToolsMenu = false;

  // Advisor states
  File? _advisorFile;
  String _advisorResumeUrl = '';
  bool _advisorUploading = false;
  String _advisorUploadError = '';
  List<String> _advisorCountries = [];

  // Deep search attachment states
  String _deepSearchAttachmentUrl = '';
  String _deepSearchAttachmentName = '';
  bool _deepSearchUploading = false;
  // bool _showCountryModal = false; // TODO: 实现国家选择模态框时使用

  String _fileNameOf(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isNotEmpty ? parts.last : path;
  }

  @override
  void initState() {
    super.initState();
    _startPlaceholderRotation();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    // 监听 SearchStore 的 pendingFill
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchStore = context.read<SearchStore>();
      if (searchStore.pendingFill != null) {
        _controller.text = searchStore.pendingFill!;
        searchStore.clearPendingFill();
        _adjustHeight();
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startPlaceholderRotation() {
    _placeholderTimer?.cancel();

    void rotatePlaceholder() {
      if (!mounted) return;
      final placeholders = _currentPlaceholders(context);
      setState(() {
        _placeholderIndex = (_placeholderIndex + 1) % placeholders.length;
      });

      final duration = _placeholderIndex == 0
          ? const Duration(seconds: 5)
          : const Duration(seconds: 3);

      _placeholderTimer = Timer(duration, rotatePlaceholder);
    }

    _placeholderTimer = Timer(const Duration(seconds: 5), rotatePlaceholder);
  }

  void _adjustHeight() {
    if (!mounted) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: _controller.text.isEmpty ? ' ' : _controller.text,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: double.infinity);
    final newHeight = (textPainter.size.height).clamp(minHeight, maxHeight);
    if ((newHeight - _textFieldHeight).abs() > 1) {
      setState(() {
        _textFieldHeight = newHeight;
      });
    }
  }

  List<String> _currentPlaceholders(BuildContext context) {
    final searchStore = context.read<SearchStore>();
    if (widget.deepSearchMode && searchStore.activeTool == null) {
      return const ['Ask'];
    }
    if (searchStore.activeTool == 'find-advisor') {
      return advisorPlaceholders;
    }
    return widget.talentMode == 'dinq' ? dinqPlaceholders : globalPlaceholders;
  }

  String _currentPlaceholder(BuildContext context) {
    if (widget.deepSearchMode) return 'Ask';
    return _currentPlaceholders(context)[_placeholderIndex];
  }

  void _handleSearch({bool simple = false}) {
    final searchStore = context.read<SearchStore>();
    // Advisor 模式
    if (searchStore.activeTool == 'find-advisor') {
      if (_advisorResumeUrl.isEmpty || _advisorUploading) return;
      widget.onAdvisorSearch?.call(
        AdvisorFormData(
          resumeUrl: _advisorResumeUrl,
          resumeName: _advisorFile == null ? null : _fileNameOf(_advisorFile!.path),
          additionalInfo: _controller.text.trim(),
          countries: _advisorCountries,
          maxAdvisors: 5,
        ),
      );
      // 重置状态
      _controller.clear();
      setState(() {
        _advisorFile = null;
        _advisorResumeUrl = '';
        _advisorCountries = [];
        _advisorUploadError = '';
      });
      searchStore.clearActiveTool();
      _adjustHeight();
      widget.onActiveToolChange?.call(null);
      return;
    }

    final query = _controller.text.trim();
    final hasAttachment = _deepSearchAttachmentUrl.isNotEmpty && !_deepSearchUploading;
    if (query.isEmpty && !hasAttachment) return;

    // DINQ 模式
    if (!widget.deepSearchMode &&
        widget.talentMode == 'dinq' &&
        widget.onDinqSearchSubmit != null) {
      widget.onDinqSearchSubmit!(query);
      _controller.clear();
      _adjustHeight();
      return;
    }

    // Global / Deep Search 模式
    widget.onSearch(
      query: query,
      simple: simple,
      attachmentUrl: hasAttachment ? _deepSearchAttachmentUrl : null,
      attachmentName: _deepSearchAttachmentName.isNotEmpty
          ? _deepSearchAttachmentName
          : null,
    );
    _controller.clear();
    setState(() {
      _deepSearchAttachmentUrl = '';
      _deepSearchAttachmentName = '';
      _deepSearchUploading = false;
    });
    _adjustHeight();
  }

  Future<void> _handleDeepSearchFileSelect() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      if (file.lengthSync() > 10 * 1024 * 1024) return;

      setState(() {
        _deepSearchAttachmentName = _fileNameOf(file.path);
        _deepSearchUploading = true;
      });

      final bytes = await file.readAsBytes();
      final url = await UploadService().uploadFile(
        bytes: bytes,
        filename: _deepSearchAttachmentName,
        contentType: 'application/pdf',
      );
      if (!mounted) return;
      setState(() {
        _deepSearchAttachmentUrl = url;
        _deepSearchUploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deepSearchAttachmentUrl = '';
        _deepSearchAttachmentName = '';
        _deepSearchUploading = false;
      });
    }
  }

  void _handleRemoveDeepSearchFile() {
    setState(() {
      _deepSearchAttachmentUrl = '';
      _deepSearchAttachmentName = '';
      _deepSearchUploading = false;
    });
  }

  Future<void> _handleFileSelect() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      // 检查文件大小（10MB）
      if (file.lengthSync() > 10 * 1024 * 1024) {
        setState(() {
          _advisorUploadError = 'File size must be less than 10MB';
        });
        return;
      }

      setState(() {
        _advisorFile = file;
        _advisorUploadError = '';
        _advisorUploading = true;
      });

      final bytes = await file.readAsBytes();
      final fileName = _fileNameOf(file.path);
      final url = await UploadService().uploadFile(
        bytes: bytes,
        filename: fileName,
        contentType: 'application/pdf',
      );

      setState(() {
        _advisorResumeUrl = url;
        _advisorUploading = false;
      });
    } catch (e) {
      setState(() {
        _advisorUploadError = 'Failed to upload file';
        _advisorFile = null;
        _advisorUploading = false;
      });
    }
  }

  void _handleRemoveFile() {
    setState(() {
      _advisorFile = null;
      _advisorResumeUrl = '';
      _advisorUploadError = '';
    });
  }

  void _handleToolSelect(String toolId) {
    final searchStore = context.read<SearchStore>();
    setState(() {
      _showToolsMenu = false;
    });
    searchStore.setActiveTool(toolId);
    widget.onActiveToolChange?.call(toolId);

    // 清除斜杠
    if (_controller.text == '/') {
      _controller.clear();
      _adjustHeight();
    }
  }

  void _handleClearTool() {
    final searchStore = context.read<SearchStore>();
    setState(() {
      _advisorFile = null;
      _advisorResumeUrl = '';
      _advisorUploadError = '';
      _advisorCountries = [];
    });
    searchStore.clearActiveTool();
    widget.onActiveToolChange?.call(null);
    _focusNode.requestFocus();
  }

  void _handleRemoveCountry(String country) {
    setState(() {
      _advisorCountries.remove(country);
    });
  }

  void _showCountrySelectModal() {
    final initial = List<String>.from(_advisorCountries);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountrySelectBottomSheet(
        initialSelected: initial,
        onConfirm: (countries) {
          setState(() {
            _advisorCountries = countries;
          });
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchStore>(
      builder: (context, searchStore, _) {
        // 监听 pendingFill
        if (searchStore.pendingFill != null &&
            _controller.text != searchStore.pendingFill) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _controller.text = searchStore.pendingFill!;
            searchStore.clearPendingFill();
            _adjustHeight();
            _focusNode.requestFocus();
          });
        }

        final isLoading = widget.loading || widget.advisorLoading;
        final inputLength = _controller.text.length;
        final showLimit = inputLength >= showLimitThreshold;
        final isGlass = widget.variant == 'glass';
        final canSearch = searchStore.activeTool == 'find-advisor'
            ? (_advisorResumeUrl.isNotEmpty && !_advisorUploading)
            : (_controller.text.trim().isNotEmpty ||
                (_deepSearchAttachmentUrl.isNotEmpty && !_deepSearchUploading));

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            if (_showToolsMenu) {
              setState(() {
                _showToolsMenu = false;
              });
            }
          },
          behavior: HitTestBehavior.translucent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 108,
              maxHeight: 400,
              maxWidth: widget.fullWidth ? 768 : 480,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isGlass ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGlass
                      ? (_isFocused
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFE5E7EB))
                      : const Color(0xFF171717),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 剩余高度 = 总高 - 底部预留(76) - 底部按钮栏(52+8+14) - 顶部 padding(12) - find-advisor 区域(若显示)
                  final bottomReserve = 76.0;
                  final bottomBarHeight = 52.0 + 8 + 14;
                  final topPadding = 12.0;
                  final advisorHeight = searchStore.activeTool == 'find-advisor'
                      ? _kAdvisorSectionApproxHeight
                      : 0.0;
                  final maxInputHeight =
                      (constraints.maxHeight -
                              bottomReserve -
                              bottomBarHeight -
                              topPadding -
                              advisorHeight)
                          .clamp(_textFieldHeight, double.infinity) -40;
                  return Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (searchStore.activeTool == 'find-advisor')
                            _buildAdvisorOptions(),
                          if (widget.deepSearchMode &&
                              (_deepSearchAttachmentName.isNotEmpty ||
                                  _deepSearchUploading))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: _buildDeepSearchAttachmentChip(),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    maxInputHeight < 0 ||
                                        maxInputHeight > _textFieldHeight
                                    ? _textFieldHeight
                                    : maxInputHeight,
                                maxHeight: maxInputHeight < 0
                                    ? 270
                                    : maxInputHeight,
                              ),
                              child: SingleChildScrollView(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  maxLines: null,
                                  maxLength: maxLength,
                                  decoration: InputDecoration(
                                    hintText: _currentPlaceholder(context),
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 14,
                                    ),
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    counterText: '',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF171717),
                                    height: 1,
                                  ),
                                  onChanged: (value) {
                                    _adjustHeight();
                                    widget.onChanged?.call(value);
                                    if (value == '/' &&
                                        searchStore.activeTool == null) {
                                      setState(() => _showToolsMenu = true);
                                    } else if (_showToolsMenu && value != '/') {
                                      setState(() => _showToolsMenu = false);
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty &&
                                        !isLoading &&
                                        canSearch) {
                                      _handleSearch();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 76), // 为底部按钮栏预留高度 (8+52+16)
                        ],
                      ),
                      // 按钮栏：固定到整个搜索框容器底部；点击时收起键盘
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => FocusScope.of(context).unfocus(),
                          behavior: HitTestBehavior.translucent,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
                            child: SizedBox(
                            height: 52,
                            child: Stack(
                              children: [
                                if (showLimit)
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        '$inputLength/$maxLength',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: inputLength >= maxLength
                                              ? Colors.red
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          if (widget.deepSearchMode &&
                                              searchStore.activeTool == null)
                                            IconButton(
                                              onPressed: _deepSearchUploading
                                                  ? null
                                                  : _handleDeepSearchFileSelect,
                                              icon: const Icon(Icons.add, size: 18),
                                              color: const Color(0xFF6B6862),
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(32, 32),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          if (!widget.deepSearchMode &&
                                              searchStore.activeTool == null)
                                            _buildTalentModeSelector(),
                                          // if (searchStore.activeTool == null)
                                          //   const SizedBox(width: 8),
                                          // _buildToolsButton(),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (searchStore.activeTool ==
                                              'find-advisor')
                                            TextButton(
                                              onPressed: _handleClearTool,
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ),
                                          if (searchStore.activeTool ==
                                              'find-advisor')
                                            const SizedBox(width: 12),
                                          _buildSearchButton(
                                            isLoading,
                                            canSearch,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeepSearchAttachmentChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E3DE)),
      ),
      child: Row(
        children: [
          _buildPdfIconWithBadge(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _deepSearchAttachmentName.isNotEmpty
                  ? _deepSearchAttachmentName
                  : 'Uploading...',
              style: const TextStyle(fontSize: 13, color: Color(0xFF2A2826)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_deepSearchUploading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: _handleRemoveDeepSearchFile,
              icon: const Icon(Icons.close, size: 16),
              color: const Color(0xFF6B6862),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  /// PDF 文档图标 + 左下角红色 "PDF" 角标
  Widget _buildPdfIconWithBadge() {
    return SizedBox(
      width: 28,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.insert_drive_file,
            size: 28,
            color: Color(0xFFE5E7EB),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorOptions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Find Advisor 标题行：毕业帽图标 + 文案 + 右侧圆形清除按钮（高度 48px，按钮 32px）
          SizedBox(
            height: 16,
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: Color(0xFF171717),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Find Advisor',
                  style: TextStyle(fontSize: 14, color: Color(0xFF171717)),
                ),
                const Spacer(),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Material(
                    color: const Color(0xFFD9D9D9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _handleClearTool,
                      customBorder: const CircleBorder(),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          size:12,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Resume row（按 UI：标签深灰加粗，上传区虚线框、浅底、居中图标与文案）
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Resume',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(fontSize: 14, color: Colors.amber),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_advisorFile == null)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _advisorUploading ? null : _handleFileSelect,
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload,
                                      size: 20,
                                      color: Color(0xFF888888),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Choose PDF file',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _DashedRectPainter(
                                    color: const Color(0xFFCCCCCC),
                                    strokeWidth: 1,
                                    borderRadius: 8,
                                    dashWidth: 4,
                                    dashSpace: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 48,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                if (_advisorUploading)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF888888),
                                      ),
                                    ),
                                  )
                                else
                                  _buildPdfIconWithBadge(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fileNameOf(_advisorFile!.path),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF171717),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 32,
                                  child: TextButton(
                                    onPressed: _handleRemoveFile,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 0,
                                      ),
                                      minimumSize: const Size(0, 32),
                                      backgroundColor: const Color(0xFFFFFFFF),
                                      foregroundColor: const Color(0xFF171717),
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Remove File'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DashedRectPainter(
                                color: const Color(0xFFCCCCCC),
                                strokeWidth: 1,
                                borderRadius: 8,
                                dashWidth: 4,
                                dashSpace: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_advisorUploadError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _advisorUploadError,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Countries row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Preferred Countries',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(optional)',
                    style: TextStyle(fontSize: 12, color: Color(0xA3303030)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._advisorCountries.map(
                    (country) => Chip(
                      label: Text(country),
                      onDeleted: () => _handleRemoveCountry(country),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      backgroundColor: const Color(0xFFF5F5F5),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showCountrySelectModal,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF6B7280),
                      side: BorderSide(
                        color: const Color(0xFFD1D5DB),
                        style: BorderStyle.solid,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTalentModeSelector() {
    final searchStore = context.read<SearchStore>();
    if (searchStore.activeTool != null) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: searchStore.activeTool != null ? 0 : 1,
      child: GestureDetector(
        onTap: () {
          // 切换模式
          final newMode = widget.talentMode == 'global' ? 'dinq' : 'global';
          widget.onTalentModeChange?.call(newMode);
          setState(() {
            _placeholderIndex = 0;
            _showToolsMenu = false;
          });
        },
        child: Container(
          width: 64,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // 滑块背景（激活状态）
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: widget.talentMode == 'global' ? 2 : 34,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // 图标
              Row(
                children: [
                  // Global Talent 选项
                  Expanded(child: _buildToggleOption('global', Icons.search)),
                  // DINQ Fellows 选项
                  Expanded(child: _buildToggleOption('dinq', Icons.bolt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String mode, IconData icon) {
    final isSelected = widget.talentMode == mode;
    return Container(
      height: 32,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 16,
        color: isSelected ? const Color(0xFF000000) : const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildToolsButton() {
    final searchStore = context.read<SearchStore>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tools button container
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showToolsMenu = !_showToolsMenu;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showToolsMenu
                        ? const Color(0xFFF5F5F5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.build,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      if (searchStore.activeTool == null)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            'Tools',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6B6B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Tools menu
            if (_showToolsMenu)
              Positioned(
                key: const ValueKey('tools-menu-dropdown'),
                top: widget.dropdownPosition == 'up' ? null : 40,
                bottom: widget.dropdownPosition == 'up' ? 40 : null,
                left: 0,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToolOption(
                          'find-advisor',
                          'Find Advisor',
                          Icons.school,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Advisor badge (显示在 Tools 按钮旁边)
        if (searchStore.activeTool == 'find-advisor')
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _buildAdvisorBadge(),
          ),
      ],
    );
  }

  Widget _buildToolOption(String toolId, String label, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleToolSelect(toolId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: Colors.amber.shade700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_return,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 6),
          const Text(
            'Advisor',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _handleClearTool,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(bool isLoading, bool canSearch) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isLoading && widget.onStop != null)
            ? widget.onStop
            : (canSearch ? () => _handleSearch() : null),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLoading
                ? const Color(0xFF171717)
                : (canSearch
                      ? const Color(0xFF171717)
                      : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(36),
          ),
          child: isLoading
              ? Center(
                  child: Container(
                    width: 9.6,
                    height: 9.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.6),
                    ),
                  ),
                )
              : Icon(
                  isLoading ? Icons.stop : Icons.arrow_upward,
                  color: canSearch ? Colors.white : const Color(0xFF9CA3AF),
                  size: 18,
                ),
        ),
      ),
    );
  }
}
