import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';

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
const int maxLength = 2000;
const int showLimitThreshold = 1800;

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
    this.onTalentModeChange,
    this.onDinqSearchSubmit,
    this.onAdvisorSearch,
    this.advisorLoading = false,
    this.onActiveToolChange,
    this.dropdownPosition = 'down',
    this.fullWidth = true,
    this.variant = 'glass',
  });

  final Function({required String query, bool simple}) onSearch;
  final VoidCallback? onStop;
  final bool loading;
  final String talentMode; // 'global' or 'dinq'
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
  String? _activeTool; // 'find-advisor' or null
  double _textFieldHeight = minHeight;
  bool _dropdownOpen = false;
  bool _showToolsMenu = false;
  
  // Advisor states
  File? _advisorFile;
  String _advisorResumeUrl = '';
  bool _advisorUploading = false;
  String _advisorUploadError = '';
  List<String> _advisorCountries = [];
  // bool _showCountryModal = false; // TODO: 实现国家选择模态框时使用

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
      final placeholders = _currentPlaceholders;
      setState(() {
        _placeholderIndex = (_placeholderIndex + 1) % placeholders.length;
      });
      
      final duration = _placeholderIndex == 0 
          ? const Duration(seconds: 5)
          : const Duration(seconds: 3);
      
      _placeholderTimer = Timer(duration, rotatePlaceholder);
    }
    
    _placeholderTimer = Timer(
      const Duration(seconds: 5),
      rotatePlaceholder,
    );
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

  List<String> get _currentPlaceholders {
    if (_activeTool == 'find-advisor') {
      return advisorPlaceholders;
    }
    return widget.talentMode == 'dinq' ? dinqPlaceholders : globalPlaceholders;
  }

  String get _currentPlaceholder {
    return _currentPlaceholders[_placeholderIndex];
  }

  void _handleSearch({bool simple = false}) {
    // Advisor 模式
    if (_activeTool == 'find-advisor') {
      if (_advisorResumeUrl.isEmpty || _advisorUploading) return;
      widget.onAdvisorSearch?.call(AdvisorFormData(
        resumeUrl: _advisorResumeUrl,
        resumeName: _advisorFile?.path.split('/').last,
        additionalInfo: _controller.text.trim(),
        countries: _advisorCountries,
        maxAdvisors: 5,
      ));
      // 重置状态
      _controller.clear();
      setState(() {
        _activeTool = null;
        _advisorFile = null;
        _advisorResumeUrl = '';
        _advisorCountries = [];
        _advisorUploadError = '';
      });
      _adjustHeight();
      widget.onActiveToolChange?.call(null);
      return;
    }

    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // DINQ 模式
    if (widget.talentMode == 'dinq' && widget.onDinqSearchSubmit != null) {
      widget.onDinqSearchSubmit!(query);
      _controller.clear();
      _adjustHeight();
      return;
    }

    // Global 模式
    widget.onSearch(query: query, simple: simple);
    _controller.clear();
    _adjustHeight();
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

      // TODO: 实现文件上传 API
      // final url = await uploadApi.uploadFile(file);
      // setState(() {
      //   _advisorResumeUrl = url;
      //   _advisorUploading = false;
      // });

      // 临时：模拟上传
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _advisorResumeUrl = 'temp_url_${file.path}';
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
    setState(() {
      _showToolsMenu = false;
      _activeTool = toolId;
    });
    widget.onActiveToolChange?.call(toolId);
    
    // 清除斜杠
    if (_controller.text == '/') {
      _controller.clear();
      _adjustHeight();
    }
  }

  void _handleClearTool() {
    setState(() {
      _activeTool = null;
      _advisorFile = null;
      _advisorResumeUrl = '';
      _advisorUploadError = '';
      _advisorCountries = [];
    });
    widget.onActiveToolChange?.call(null);
    _focusNode.requestFocus();
  }

  void _handleRemoveCountry(String country) {
    setState(() {
      _advisorCountries.remove(country);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchStore>(
      builder: (context, searchStore, _) {
        // 监听 pendingFill
        if (searchStore.pendingFill != null && _controller.text != searchStore.pendingFill) {
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
        final canSearch = _activeTool == 'find-advisor'
            ? (_advisorResumeUrl.isNotEmpty && !_advisorUploading)
            : _controller.text.trim().isNotEmpty;

        return GestureDetector(
          onTap: () {
            // 点击外部时关闭下拉菜单
            if (_dropdownOpen || _showToolsMenu) {
              setState(() {
                _dropdownOpen = false;
                _showToolsMenu = false;
              });
            }
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 200,
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
              child: Stack(
                children: [
                  // 上方内容：由子元素决定高度，父容器自适应；总高度受 ConstrainedBox 的 maxHeight 限制
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_activeTool == 'find-advisor')
                        _buildAdvisorOptions(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: _textFieldHeight,
                            maxHeight: _activeTool == 'find-advisor'
                                ? 124
                                : 200,
                          ),
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: null,
                              maxLength: maxLength,
                              decoration: InputDecoration(
                                hintText: _currentPlaceholder,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF171717),
                                height: 1.5,
                              ),
                              onChanged: (value) {
                                _adjustHeight();
                                if (value == '/' && _activeTool == null) {
                                  setState(() => _showToolsMenu = true);
                                } else if (_showToolsMenu && value != '/') {
                                  setState(() => _showToolsMenu = false);
                                }
                              },
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty && !isLoading && canSearch) {
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
                  // 按钮栏：固定到整个搜索框容器底部
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    if (_activeTool == null)
                                      _buildTalentModeSelector(),
                                    if (_activeTool == null)
                                      const SizedBox(width: 8),
                                    _buildToolsButton(),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (_activeTool == 'find-advisor')
                                      TextButton(
                                        onPressed: _handleClearTool,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    if (_activeTool == 'find-advisor')
                                      const SizedBox(width: 12),
                                    _buildSearchButton(isLoading, canSearch),
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
              ],
            ),
            ),
          ),
        );
      },
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
          // Resume row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.upload, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  const Text(
                    'Resume',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (_advisorFile == null)
                    TextButton.icon(
                      onPressed: _advisorUploading ? null : _handleFileSelect,
                      icon: const Icon(Icons.description, size: 16),
                      label: const Text('Choose PDF file'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_advisorUploading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            )
                          else
                            const Icon(Icons.description, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: Text(
                              _advisorFile!.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: const Color(0xFF9CA3AF),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _handleRemoveFile,
                          ),
                        ],
                      ),
                    ),
                  if (_advisorUploadError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _advisorUploadError,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
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
                  const Icon(Icons.language, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  const Text(
                    'Preferred Countries',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(optional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._advisorCountries.map((country) => Chip(
                        label: Text(country),
                        onDeleted: () => _handleRemoveCountry(country),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        backgroundColor: const Color(0xFFF5F5F5),
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      )),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: 实现国家选择模态框
                      // setState(() {
                      //   _showCountryModal = true;
                      // });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    if (_activeTool != null) {
      return const SizedBox.shrink();
    }
    
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _activeTool != null ? 0 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Trigger button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _dropdownOpen = !_dropdownOpen;
                  _showToolsMenu = false; // 关闭工具菜单
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.talentMode == 'global'
                        ? const Icon(Icons.language, size: 16, color: Color(0xFF374151))
                        : Image.asset(
                            'assets/logo/dinq-black.png',
                            width: 14,
                            height: 14,
                            errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 14),
                          ),
                    const SizedBox(width: 8),
                    Text(
                      widget.talentMode == 'global' ? 'Global Talent' : 'DINQ Fellows',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.rotate(
                      angle: _dropdownOpen 
                          ? (widget.dropdownPosition == 'up' ? 0 : 3.14159)
                          : (widget.dropdownPosition == 'up' ? 3.14159 : 0),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dropdown menu
          if (_dropdownOpen)
            Positioned(
              key: const ValueKey('talent-mode-dropdown'),
              top: widget.dropdownPosition == 'up' ? null : 40,
              bottom: widget.dropdownPosition == 'up' ? 40 : null,
              left: 0,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      _buildModeOption('global', 'Global Talent', Icons.language),
                      _buildModeOption('dinq', 'DINQ Fellows', Icons.star),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String mode, String label, IconData icon) {
    final isSelected = widget.talentMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onTalentModeChange?.call(mode);
          setState(() {
            _dropdownOpen = false;
            _placeholderIndex = 0;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: isSelected ? const Color(0xFFF5F5F5) : Colors.white,
          child: Row(
            children: [
              mode == 'global'
                  ? const Icon(Icons.language, size: 16, color: Color(0xFF374151))
                  : Image.asset(
                      'assets/logo/dinq-black.png',
                      width: 14,
                      height: 14,
                      errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 14),
                    ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsButton() {
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
                    _dropdownOpen = false; // 关闭模式选择器
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showToolsMenu ? const Color(0xFFF5F5F5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build, size: 16, color: Color(0xFF6B7280)),
                      if (_activeTool == null)
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
                        _buildToolOption('find-advisor', 'Find Advisor', Icons.school),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Advisor badge (显示在 Tools 按钮旁边)
        if (_activeTool == 'find-advisor')
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
              const Icon(Icons.keyboard_return, size: 14, color: Color(0xFF9CA3AF)),
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
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B6B),
            ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLoading
                ? const Color(0xFF171717)
                : (canSearch ? const Color(0xFF171717) : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
