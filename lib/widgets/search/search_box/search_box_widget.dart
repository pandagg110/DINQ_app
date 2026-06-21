import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/upload_service.dart';
import '../../../stores/search_store.dart';
import 'advisor_panel.dart';
import 'analysis_panel.dart';
import 'citation_panel.dart';
import 'model_channels.dart';
import 'model_provider_selector.dart';
import 'search_box_types.dart';
import 'tool_badge.dart';
import 'tool_switch_confirm_dialog.dart';
import 'tools_menu.dart';

export 'search_box_types.dart';

/// 与 TSX SearchBox 对齐
class SearchBoxWidget extends StatefulWidget {
  const SearchBoxWidget({
    super.key,
    this.fullWidth = true,
    this.variant = 'default',
    this.dropdownPosition = 'down',
    this.onAdvisorSearch,
    this.advisorLoading = false,
    this.onCitationSearch,
    this.citationLoading = false,
    this.citationMode,
    this.onCitationModeChange,
    this.onAnalysisSearch,
    this.analysisLoading = false,
    this.analysisCandidates,
    this.onClearAnalysisCandidates,
    this.analysisPlatform,
    this.onAnalysisPlatformChange,
    this.activeTool,
    this.onActiveToolChange,
    this.onDeepSearch,
    this.deepSearchLoading = false,
    this.onDeepSearchStop,
    this.modelOptions,
    this.modelProvider,
    this.onModelProviderChange,
    this.confirmToolSwitch = false,
    this.isMobile = true,
  });

  final bool fullWidth;
  final String variant;
  final String dropdownPosition;
  final ValueChanged<AdvisorFormData>? onAdvisorSearch;
  final bool advisorLoading;
  final ValueChanged<({String query})>? onCitationSearch;
  final bool citationLoading;
  final CitationMode? citationMode;
  final ValueChanged<CitationMode>? onCitationModeChange;
  final ValueChanged<AnalysisSearchParams>? onAnalysisSearch;
  final bool analysisLoading;
  final List<Map<String, dynamic>>? analysisCandidates;
  final VoidCallback? onClearAnalysisCandidates;
  final String? analysisPlatform;
  final ValueChanged<String>? onAnalysisPlatformChange;
  final String? activeTool;
  final ValueChanged<String?>? onActiveToolChange;
  final ValueChanged<DeepSearchSubmitParams>? onDeepSearch;
  final bool deepSearchLoading;
  final VoidCallback? onDeepSearchStop;
  final List<ModelOption>? modelOptions;
  final String? modelProvider;
  final ValueChanged<String>? onModelProviderChange;
  final bool confirmToolSwitch;
  final bool isMobile;

  @override
  State<SearchBoxWidget> createState() => _SearchBoxWidgetState();
}

class _SearchBoxWidgetState extends State<SearchBoxWidget> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ToolPanelHandle _panelHandle = ToolPanelHandle();
  final GlobalKey _toolsAnchorKey = GlobalKey();

  bool _isFocused = false;
  bool _showToolsMenu = false;
  bool _panelCanSubmit = false;
  double _textHeight = kSearchBoxMinHeight;

  String _attachmentUrl = '';
  String _attachmentName = '';
  bool _attachmentUploading = false;

  bool get _isDeepSearchMode => widget.activeTool == null;

  bool get _isLoading =>
      widget.advisorLoading ||
      widget.citationLoading ||
      widget.analysisLoading ||
      widget.deepSearchLoading;

  bool get _hasDeepSearchInput =>
      _inputController.text.trim().isNotEmpty || _attachmentUrl.isNotEmpty;

  bool get _isSendDisabled =>
      !_isDeepSearchMode ? !_panelCanSubmit : !_hasDeepSearchInput || _attachmentUploading;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingFill());
  }

  @override
  void didUpdateWidget(covariant SearchBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTool != widget.activeTool) {
      setState(() => _panelCanSubmit = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _consumePendingFill() {
    if (!_isDeepSearchMode) return;
    final store = context.read<SearchStore>();
    final fill = store.pendingFill;
    if (fill == null) return;
    _inputController.text = fill;
    store.clearPendingFill();
    _adjustHeight();
    _focusNode.requestFocus();
    setState(() {});
  }

  void _adjustHeight() {
    final painter = TextPainter(
      text: TextSpan(
        text: _inputController.text.isEmpty ? ' ' : _inputController.text,
        style: const TextStyle(fontSize: 16, height: 1.75),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    final h = painter.size.height.clamp(kSearchBoxMinHeight, kSearchBoxMaxHeight);
    if ((h - _textHeight).abs() > 1 && mounted) {
      setState(() => _textHeight = h);
    }
  }

  void _handleDeepSearchSubmit() {
    if (_attachmentUploading) return;
    final query = _inputController.text.trim();
    if (query.isEmpty && _attachmentUrl.isEmpty) return;
    widget.onDeepSearch?.call(
      DeepSearchSubmitParams(
        query: query,
        modelProvider: widget.modelProvider ?? 'anthropic-hao',
        attachment: _attachmentUrl.isNotEmpty ? _attachmentUrl : null,
        attachmentName: _attachmentName.isNotEmpty ? _attachmentName : null,
      ),
    );
    _inputController.clear();
    setState(() {
      _attachmentUrl = '';
      _attachmentName = '';
      _textHeight = kSearchBoxMinHeight;
    });
  }

  void _handleSubmit() {
    if (!_isDeepSearchMode) {
      _panelHandle.trySubmit();
    } else {
      _handleDeepSearchSubmit();
    }
  }

  void _handleStop() => widget.onDeepSearchStop?.call();

  void _clearAttachment() {
    setState(() {
      _attachmentUrl = '';
      _attachmentName = '';
      _attachmentUploading = false;
    });
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kAttachmentExtensions.toList(),
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final ext = file.path.split('.').last.toLowerCase();
    if (!kAttachmentExtensions.contains(ext)) return;

    setState(() {
      _attachmentName = file.path.split(RegExp(r'[\\/]')).last;
      _attachmentUploading = true;
      _attachmentUrl = '';
    });

    try {
      final bytes = await file.readAsBytes();
      final url = await UploadService().uploadFile(
        bytes: bytes,
        filename: _attachmentName,
      );
      if (!mounted) return;
      setState(() {
        _attachmentUrl = url;
        _attachmentUploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      _clearAttachment();
    }
  }

  void _handleToolSelect(SearchToolDefinition tool) async {
    setState(() => _showToolsMenu = false);
    if (widget.activeTool == tool.id) return;

    Future<void> apply() async {
      _clearAttachment();
      widget.onActiveToolChange?.call(tool.id);
    }

    if (widget.confirmToolSwitch) {
      final confirmed = await showToolSwitchConfirm(
        context: context,
        toolLabel: tool.label,
        toolId: tool.id,
        isMobile: widget.isMobile,
      );
      if (confirmed != true || !mounted) return;
    }

    await apply();
  }

  void _handleClearTool() {
    widget.onActiveToolChange?.call(null);
    widget.onClearAnalysisCandidates?.call();
    setState(() => _panelCanSubmit = false);
    _focusNode.requestFocus();
  }

  Widget? _buildToolPanel() {
    switch (widget.activeTool) {
      case 'find-advisor':
        if (widget.onAdvisorSearch == null) return null;
        return AdvisorPanel(
          key: ValueKey('advisor-${widget.activeTool}'),
          onSearch: widget.onAdvisorSearch!,
          onClearTool: _handleClearTool,
          onCanSubmitChange: (v) => setState(() => _panelCanSubmit = v),
          panelHandle: _panelHandle,
          isMobile: widget.isMobile,
        );
      case 'who-cites-me':
        if (widget.onCitationSearch == null) return null;
        return CitationPanel(
          key: ValueKey('citation-${widget.citationMode}'),
          onSearch: widget.onCitationSearch!,
          onClearTool: _handleClearTool,
          onCanSubmitChange: (v) => setState(() => _panelCanSubmit = v),
          panelHandle: _panelHandle,
          mode: widget.citationMode ?? CitationMode.author,
          onModeChange: widget.onCitationModeChange,
        );
      case 'analysis':
        if (widget.onAnalysisSearch == null) return null;
        return AnalysisPanel(
          key: ValueKey('analysis-${widget.analysisPlatform}'),
          onSearch: widget.onAnalysisSearch!,
          onClearTool: _handleClearTool,
          onCanSubmitChange: (v) => setState(() => _panelCanSubmit = v),
          panelHandle: _panelHandle,
          platform: widget.analysisPlatform ?? 'scholar',
          onPlatformChange: widget.onAnalysisPlatformChange,
          candidates: widget.analysisCandidates,
          onClearCandidates: widget.onClearAnalysisCandidates,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGlass = widget.variant == 'glass';
    final inputLength = _inputController.text.length;
    final showLimit = _isDeepSearchMode && inputLength >= kSearchBoxShowLimitThreshold;
    final toolPanel = _buildToolPanel();

    return Consumer<SearchStore>(
      builder: (context, searchStore, _) {
        if (_isDeepSearchMode && searchStore.pendingFill != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingFill());
        }

        return Container(
          clipBehavior: Clip.none,
          width: widget.fullWidth ? double.infinity : 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isMobile ? 28 : 16),
            border: Border.all(
              color: isGlass
                  ? (_isFocused ? const Color(0xFFC0C0C0) : const Color(0xFFD5D3CE))
                  : const Color(0xFFE5E3DE),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (toolPanel != null) toolPanel,
              if (_isDeepSearchMode) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_attachmentName.isNotEmpty || _attachmentUploading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _AttachmentChip(
                            name: _attachmentName.isNotEmpty ? _attachmentName : 'Uploading...',
                            uploading: _attachmentUploading,
                            onRemove: _clearAttachment,
                          ),
                        ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: kSearchBoxMinHeight,
                          maxHeight: kSearchBoxMaxHeight,
                        ),
                        child: TextField(
                          controller: _inputController,
                          focusNode: _focusNode,
                          maxLines: null,
                          maxLength: kSearchBoxMaxLength,
                          decoration: searchBoxInputDecoration(
                            hintText: widget.isMobile ? 'Ask' : 'Ask DINQ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                            height: 1.75,
                          ),
                          onChanged: (_) {
                            _adjustHeight();
                            setState(() {});
                          },
                          onSubmitted: (_) {
                            if (!_isLoading && !_isSendDisabled) _handleDeepSearchSubmit();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (showLimit)
                      Text(
                        '$inputLength/$kSearchBoxMaxLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: inputLength >= kSearchBoxMaxLength
                              ? Colors.red
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (_isDeepSearchMode)
                              IconButton(
                                onPressed: _attachmentUploading ? null : _pickAttachment,
                                icon: const Icon(Icons.add, size: 18),
                                color: const Color(0xFF6B6862),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(32, 32),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            Stack(
                              clipBehavior: Clip.none,
                              key: _toolsAnchorKey,
                              children: [
                                Material(
                                  color: _showToolsMenu
                                      ? const Color(0xFFF5F4F0)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () {
                                      if (widget.isMobile) {
                                        showToolsBottomSheet(
                                          context,
                                          activeTool: widget.activeTool,
                                          onSelect: _handleToolSelect,
                                        );
                                      } else {
                                        setState(() => _showToolsMenu = !_showToolsMenu);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.widgets_outlined,
                                            size: 16,
                                            color: Color(0xFF6B6862),
                                          ),
                                          if (widget.activeTool == null && !widget.isMobile) ...[
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Tools',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF6B6862),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (!widget.isMobile)
                                  Positioned(
                                    left: 0,
                                    bottom: widget.dropdownPosition == 'up' ? 40 : null,
                                    top: widget.dropdownPosition == 'down' ? 40 : null,
                                    child: ToolsMenu(
                                      visible: _showToolsMenu,
                                      onSelect: _handleToolSelect,
                                      onClose: () => setState(() => _showToolsMenu = false),
                                      position: widget.dropdownPosition,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            ToolBadge(
                              tool: widget.activeTool,
                              onClear: _handleClearTool,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_isDeepSearchMode &&
                                (widget.modelOptions?.isNotEmpty ?? false))
                              ModelProviderSelector(
                                options: widget.modelOptions!,
                                modelProvider: widget.modelProvider ??
                                    widget.modelOptions!.first.value,
                                onModelProviderChange:
                                    widget.onModelProviderChange ?? (_) {},
                                dropdownPosition: widget.dropdownPosition,
                                isMobile: widget.isMobile,
                              ),
                            if (_isDeepSearchMode &&
                                (widget.modelOptions?.isNotEmpty ?? false))
                              const SizedBox(width: 12),
                            _SendButton(
                              isLoading: _isLoading,
                              isDisabled: _isSendDisabled,
                              attachmentUploading: _attachmentUploading,
                              onTap: _isLoading ? _handleStop : _handleSubmit,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.name,
    required this.uploading,
    required this.onRemove,
  });

  final String name;
  final bool uploading;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E3DE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18, color: Color(0xFFD1CEC6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, color: Color(0xFF2A2826)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (uploading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              color: const Color(0xFF6B6862),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isLoading,
    required this.isDisabled,
    required this.attachmentUploading,
    required this.onTap,
  });

  final bool isLoading;
  final bool isDisabled;
  final bool attachmentUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isLoading || !isDisabled) ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLoading
                ? Colors.white
                : isDisabled
                    ? const Color(0xFFE5E3DE)
                    : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: isLoading ? Border.all(color: const Color(0xFFD5D3CE)) : null,
          ),
          child: Center(
            child: isLoading
                ? Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2826),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : attachmentUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: isDisabled ? const Color(0xFFB5B3AE) : Colors.white,
                      ),
          ),
        ),
      ),
    );
  }
}
