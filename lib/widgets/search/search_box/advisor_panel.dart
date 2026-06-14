import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/upload_service.dart';
import '../../../stores/search_store.dart';
import 'country_select_sheet.dart';
import 'search_box_types.dart';

/// 与 TSX AdvisorPanel 对齐
class AdvisorPanel extends StatefulWidget {
  const AdvisorPanel({
    super.key,
    required this.onSearch,
    required this.onClearTool,
    required this.onCanSubmitChange,
    required this.panelHandle,
    this.isMobile = true,
  });

  final ValueChanged<AdvisorFormData> onSearch;
  final VoidCallback onClearTool;
  final ValueChanged<bool> onCanSubmitChange;
  final ToolPanelHandle panelHandle;
  final bool isMobile;

  @override
  State<AdvisorPanel> createState() => _AdvisorPanelState();
}

class _AdvisorPanelState extends State<AdvisorPanel> {
  final TextEditingController _inputController = TextEditingController();
  File? _file;
  String _resumeUrl = '';
  bool _uploading = false;
  String _uploadError = '';
  List<String> _countries = [];
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;
  double _textHeight = kSearchBoxMinHeight;

  static const _placeholders = [
    'Describe your ideal advisor, e.g. research interests, mentoring style...',
    'Looking for a professor who specializes in NLP and has industry experience',
    'I prefer advisors who encourage independent research and collaboration',
    'Seeking someone with strong publication record in computer vision',
  ];

  bool get _canSubmit => _resumeUrl.isNotEmpty && !_uploading;

  void _submit() {
    if (!_canSubmit) return;
    widget.onSearch(
      AdvisorFormData(
        resumeUrl: _resumeUrl,
        resumeName: _file?.path.split(RegExp(r'[\\/]')).last,
        additionalInfo: _inputController.text.trim(),
        countries: _countries,
        maxAdvisors: 5,
      ),
    );
    _inputController.clear();
    setState(() {
      _file = null;
      _resumeUrl = '';
      _countries = [];
      _uploadError = '';
      _textHeight = kSearchBoxMinHeight;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.panelHandle.getCanSubmit = () => _canSubmit;
    widget.panelHandle.submit = _submit;
    _startPlaceholderRotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingFill();
      widget.onCanSubmitChange(_canSubmit);
    });
  }

  void _startPlaceholderRotation() {
    _placeholderTimer?.cancel();
    void rotate() {
      if (!mounted) return;
      setState(() {
        _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
      });
      _placeholderTimer = Timer(
        Duration(seconds: _placeholderIndex == 0 ? 5 : 3),
        rotate,
      );
    }
    _placeholderTimer = Timer(const Duration(seconds: 5), rotate);
  }

  void _consumePendingFill() {
    final store = context.read<SearchStore>();
    final fill = store.pendingFill;
    if (fill == null) return;
    _inputController.text = fill;
    store.clearPendingFill();
    _adjustHeight();
    widget.onCanSubmitChange(_canSubmit);
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

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    if (file.lengthSync() > 10 * 1024 * 1024) {
      setState(() => _uploadError = 'File size must be less than 10MB');
      widget.onCanSubmitChange(_canSubmit);
      return;
    }
    setState(() {
      _file = file;
      _uploadError = '';
      _uploading = true;
    });
    widget.onCanSubmitChange(_canSubmit);
    try {
      final bytes = await file.readAsBytes();
      final name = file.path.split(RegExp(r'[\\/]')).last;
      final url = await UploadService().uploadFile(
        bytes: bytes,
        filename: name,
        contentType: 'application/pdf',
      );
      if (!mounted) return;
      setState(() {
        _resumeUrl = url;
        _uploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploadError = 'Failed to upload file';
        _file = null;
        _uploading = false;
      });
    }
    widget.onCanSubmitChange(_canSubmit);
  }

  void _removeFile() {
    setState(() {
      _file = null;
      _resumeUrl = '';
      _uploadError = '';
    });
    widget.onCanSubmitChange(_canSubmit);
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: kToolPanelHeaderDecoration,
          child: _file == null && _countries.isEmpty
              ? Row(
                  children: [
                    _optionButton(
                      icon: Icons.upload_outlined,
                      label: 'Resume PDF',
                      requiredMark: true,
                      onTap: _uploading ? null : _pickResume,
                    ),
                    const SizedBox(width: 8),
                    _optionButton(
                      icon: Icons.public_outlined,
                      label: 'Region',
                      onTap: () => CountrySelectSheet.show(
                        context,
                        initialSelected: _countries,
                        onConfirm: (c) => setState(() => _countries = c),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_file == null)
                          _optionButton(
                            icon: Icons.upload_outlined,
                            label: 'Resume PDF',
                            requiredMark: true,
                            onTap: _uploading ? null : _pickResume,
                          )
                        else
                          _resumeChip(),
                        if (_uploadError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _uploadError,
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    if (_countries.isNotEmpty || _file != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._countries.map(
                            (c) => Chip(
                              label: Text(c),
                              onDeleted: () => setState(() => _countries.remove(c)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              backgroundColor: const Color(0xFFF0EFE9),
                            ),
                          ),
                          _optionButton(
                            icon: Icons.public_outlined,
                            label: 'Region',
                            onTap: () => CountrySelectSheet.show(
                              context,
                              initialSelected: _countries,
                              onConfirm: (v) => setState(() => _countries = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: TextField(
            controller: _inputController,
            maxLines: null,
            maxLength: kSearchBoxMaxLength,
            decoration: searchBoxInputDecoration(
              hintText: widget.isMobile
                  ? 'Describe your advisor'
                  : _placeholders[_placeholderIndex],
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937), height: 1.75),
            onChanged: (_) {
              _adjustHeight();
              widget.onCanSubmitChange(_canSubmit);
            },
            onSubmitted: (_) {
              if (_canSubmit) _submit();
            },
          ),
        ),
      ],
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String label,
    bool requiredMark = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF9E9B93)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF9E9B93))),
              if (requiredMark)
                const Text(' *', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD5D3CE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_uploading)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insert_drive_file, color: Colors.white, size: 18),
            ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              _file?.path.split(RegExp(r'[\\/]')).last ?? 'Resume.pdf',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _removeFile,
            child: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
