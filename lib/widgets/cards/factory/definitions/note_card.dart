import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../card_definition.dart';

class NoteCardDefinition extends CardDefinition {
  @override
  String get type => 'NOTE';

  @override
  String get icon => '/icons/note.svg';

  @override
  String get name => 'Note';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
      );

  @override
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    return {
      'text': rawMetadata['text'] ?? '',
      'fontSize': rawMetadata['fontSize'] ?? 16,
      'fontColor': rawMetadata['fontColor'] ?? '#171717',
      'bgColor': rawMetadata['bgColor'] ?? '#FFFFFF',
      'align': rawMetadata['align'] ?? ['left', 'center'],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    // debugPrint('params: ${params.editable}');
    debugPrint('isSelected: ${params.isSelected}');
    final isSelected = params.isSelected;
    final text = params.card.data.metadata['text']?.toString() ??
        params.card.data.metadata['content']?.toString() ??
        params.card.data.description;
    final fontSize = params.card.data.metadata['fontSize'] ?? 16;
    final fontColorStr = params.card.data.metadata['fontColor']?.toString() ?? '#171717';
    final bgColorStr = params.card.data.metadata['bgColor']?.toString() ?? '#FFFFFF';
    final align = params.card.data.metadata['align'] as List<dynamic>? ?? ['left', 'center'];

    // Parse colors
    Color fontColor = _parseColor(fontColorStr);
    Color bgColor = _parseColor(bgColorStr);
    
    // Parse alignment: align is [horizontalAlign, verticalAlign]
    final horizontalAlign = align.isNotEmpty ? align[0]?.toString() ?? 'left' : 'left';
    final verticalAlign = align.length > 1 ? align[1]?.toString() ?? 'center' : 'center';
    
    // Map horizontal alignment to TextAlign
    TextAlign textAlign = TextAlign.left;
    if (horizontalAlign == 'center') {
      textAlign = TextAlign.center;
    } else if (horizontalAlign == 'right') {
      textAlign = TextAlign.right;
    }
    
    // Map vertical alignment to MainAxisAlignment
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center;
    if (verticalAlign == 'top') {
      mainAxisAlignment = MainAxisAlignment.start;
    } else if (verticalAlign == 'bottom') {
      mainAxisAlignment = MainAxisAlignment.end;
    }

    // 检测是否为 HTML 内容
    final bool isHtml = _isHtmlContent(text);
    final String displayText = text;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 如果选中且可编辑，显示可编辑的文本字段
            if (isSelected && params.editable)
              _EditableNoteContent(
                key: ValueKey('editable_${params.card.id}_$isSelected'),
                initialText: displayText,
                isHtml: isHtml,
                fontSize: (fontSize as num).toDouble(),
                fontColor: fontColor,
                textAlign: textAlign,
                isSelected: isSelected,
                onChanged: (newText) {
                  // 更新 metadata
                  final updatedMetadata = {
                    ...params.card.data.metadata,
                    'text': newText,
                  };
                  params.onUpdate(updatedMetadata);
                },
              )
            else
              // 非编辑模式，显示只读内容
              isHtml
                  ? Html(
                      data: displayText,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize((fontSize as num).toDouble()),
                          color: fontColor,
                          textAlign: textAlign == TextAlign.center
                              ? TextAlign.center
                              : textAlign == TextAlign.right
                                  ? TextAlign.right
                                  : TextAlign.left,
                        ),
                      },
                    )
                  : Text(
                      displayText,
                      style: TextStyle(
                        fontSize: (fontSize as num).toDouble(),
                        color: fontColor,
                      ),
                      textAlign: textAlign,
                    ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF171717);
    } catch (e) {
      return const Color(0xFF171717);
    }
  }

  /// 检测文本是否包含 HTML 标签
  bool _isHtmlContent(String? text) {
    if (text == null || text.isEmpty) return false;
    // 简单的 HTML 标签检测
    final htmlTagPattern = RegExp(r'<[^>]+>');
    return htmlTagPattern.hasMatch(text);
  }
}

/// 可编辑的笔记内容组件
class _EditableNoteContent extends StatefulWidget {
  const _EditableNoteContent({
    super.key,
    required this.initialText,
    required this.isHtml,
    required this.fontSize,
    required this.fontColor,
    required this.textAlign,
    required this.isSelected,
    required this.onChanged,
  });

  final String initialText;
  final bool isHtml;
  final double fontSize;
  final Color fontColor;
  final TextAlign textAlign;
  final bool isSelected;
  final ValueChanged<String> onChanged;

  @override
  State<_EditableNoteContent> createState() => _EditableNoteContentState();
}

class _EditableNoteContentState extends State<_EditableNoteContent> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // 如果是 HTML，提取纯文本用于编辑
    final textToEdit = widget.isHtml
        ? _stripHtmlTags(widget.initialText)
        : widget.initialText;
    _controller = TextEditingController(text: textToEdit);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    // 如果被选中，自动聚焦并移动光标到末尾
    if (widget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocusAndMoveToEnd();
      });
    }
  }

  @override
  void didUpdateWidget(_EditableNoteContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果文本发生变化且不在编辑状态，更新控制器
    if (oldWidget.initialText != widget.initialText && !_isFocused) {
      final textToEdit = widget.isHtml
          ? _stripHtmlTags(widget.initialText)
          : widget.initialText;
      _controller.text = textToEdit;
    }
    
    // 如果从非选中变为选中，自动聚焦并移动光标到末尾
    if (!oldWidget.isSelected && widget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocusAndMoveToEnd();
      });
    }
  }
  
  void _requestFocusAndMoveToEnd() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    // 移动光标到文本末尾
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.text.isNotEmpty) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isFocused) {
      // 失去焦点时保存更改
      setState(() => _isFocused = false);
      widget.onChanged(_controller.text);
    } else if (_focusNode.hasFocus) {
      setState(() => _isFocused = true);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 移除 HTML 标签，提取纯文本
  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      minLines: 1,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.fontColor,
      ),
      textAlign: widget.textAlign,
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintText: 'Enter your note...',
        hintStyle: TextStyle(
          color: widget.fontColor.withOpacity(0.5),
        ),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onChanged: (value) {
        // 实时保存更改
        widget.onChanged(value);
      },
      onSubmitted: (value) {
        widget.onChanged(value);
      },
      focusNode: _focusNode,
    );
  }
}

