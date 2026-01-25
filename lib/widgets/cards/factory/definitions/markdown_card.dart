import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/toast_util.dart';
import '../../../../services/upload_service.dart';
import '../card_definition.dart';

/// 自定义内联代码渲染器，匹配 TSX 版本的样式
class InlineCodeBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    if (text.isEmpty) return null;

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFDFDFDF),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
          fontFamily: preferredStyle?.fontFamily,
        ),
      ),
    );
  }
}

/// 自定义链接渲染器，匹配 TSX 版本的样式
class LinkBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final href = element.attributes['href'];
    final text = element.textContent;
    if (href == null || text.isEmpty) return null;

    return GestureDetector(
      onTap: () {
        launchUrl(
          Uri.parse(href),
          mode: LaunchMode.externalApplication,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFDFDFDF),
            width: 0.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
            decoration: TextDecoration.none,
            fontFamily: preferredStyle?.fontFamily,
          ),
        ),
      ),
    );
  }
}

class MarkdownCardDefinition extends CardDefinition {
  @override
  String get type => 'MARKDOWN';

  @override
  String get icon => '/icons/markdown.svg';

  @override
  String get name => 'Markdown';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
    desktop: CardSizeConfig(supported: ['4x4'], defaultSize: '4x4'),
    mobile: CardSizeConfig(supported: ['4x4'], defaultSize: '4x4'),
  );

  @override
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
    return {
      'url': rawMetadata['url'] ?? '',
      'content':
          rawMetadata['content'] ??
          "**This is your title**\n\nthis is your description content, and your **name**, and *more*\n\n`tag`[dinq.me](https://dinq.me)",
      'tag': rawMetadata['tag'] ?? 'CONFERENCE / TAG',
      'isVideo': rawMetadata['isVideo'] ?? false,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return _MarkdownCardWidget(
      card: params.card,
      size: params.size,
      editable: params.editable,
      isSelected: params.isSelected,
      onUpdate: params.onUpdate,
    );
  }
}

class _MarkdownCardWidget extends StatefulWidget {
  const _MarkdownCardWidget({
    required this.card,
    required this.size,
    required this.editable,
    required this.isSelected,
    required this.onUpdate,
  });

  final dynamic card;
  final String size;
  final bool editable;
  final bool isSelected;
  final Function(Map<String, dynamic>) onUpdate;

  @override
  State<_MarkdownCardWidget> createState() => _MarkdownCardWidgetState();
}

class _MarkdownCardWidgetState extends State<_MarkdownCardWidget> {
  final UploadService _uploadService = UploadService();
  final TextEditingController _markdownController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _markdownFocusNode = FocusNode();
  final FocusNode _tagFocusNode = FocusNode();

  String _markdownContent = '';
  String _tag = 'CONFERENCE / TAG';
  String _mediaUrl = '';
  bool _isVideo = false;
  bool _isEditingMarkdown = false;
  bool _isEditingTag = false;
  bool _isUploading = false;
  bool _mediaError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _markdownFocusNode.addListener(_onMarkdownFocusChange);
    _tagFocusNode.addListener(_onTagFocusChange);
  }

  @override
  void didUpdateWidget(_MarkdownCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.data.metadata != widget.card.data.metadata) {
      _loadData();
    }
    // 如果从非选中变为选中，且正在编辑 markdown，自动聚焦
    if (!oldWidget.isSelected && widget.isSelected && _isEditingMarkdown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markdownFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _markdownFocusNode.removeListener(_onMarkdownFocusChange);
    _tagFocusNode.removeListener(_onTagFocusChange);
    _markdownController.dispose();
    _tagController.dispose();
    _markdownFocusNode.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _loadData() {
    final metadata = widget.card.data.metadata;
    setState(() {
      _mediaUrl = metadata['url']?.toString() ?? '';
      _markdownContent =
          metadata['content']?.toString() ??
          "**This is your title**\n\nthis is your description content, and your **name**, and *more*\n\n`tag`[dinq.me](https://dinq.me)";
      _tag = metadata['tag']?.toString() ?? 'CONFERENCE / TAG';
      _isVideo = metadata['isVideo'] == true;
      _markdownController.text = _markdownContent;
      _tagController.text = _tag;
    });
  }

  void _onMarkdownFocusChange() {
    if (!_markdownFocusNode.hasFocus && _isEditingMarkdown) {
      setState(() => _isEditingMarkdown = false);
      _saveMarkdown();
    }
  }

  void _onTagFocusChange() {
    if (!_tagFocusNode.hasFocus && _isEditingTag) {
      setState(() => _isEditingTag = false);
      _saveTag();
    }
  }

  void _saveMarkdown() {
    final newContent = _markdownController.text;
    if (newContent != _markdownContent) {
      setState(() => _markdownContent = newContent);
      widget.onUpdate({
        ...widget.card.data.metadata,
        'url': _mediaUrl,
        'content': _markdownContent,
        'tag': _tag,
        'isVideo': _isVideo,
      });
    }
  }

  void _saveTag() {
    final newTag = _tagController.text.trim();
    if (newTag != _tag) {
      setState(() => _tag = newTag.isEmpty ? 'CONFERENCE / TAG' : newTag);
      widget.onUpdate({
        ...widget.card.data.metadata,
        'url': _mediaUrl,
        'content': _markdownContent,
        'tag': _tag,
        'isVideo': _isVideo,
      });
    }
  }

  Future<void> _handleMediaUpload() async {
    if (!widget.editable) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      final fileBytes = await File(file.path!).readAsBytes();
      final isVideoFile =
          file.extension?.toLowerCase() == 'mp4' ||
          file.extension?.toLowerCase() == 'mov' ||
          file.extension?.toLowerCase() == 'avi';
      final isImageFile =
          file.extension?.toLowerCase() == 'jpg' ||
          file.extension?.toLowerCase() == 'jpeg' ||
          file.extension?.toLowerCase() == 'png' ||
          file.extension?.toLowerCase() == 'gif' ||
          file.extension?.toLowerCase() == 'webp';

      if (!isImageFile && !isVideoFile) {
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: 'Upload Failed',
            description: 'Please upload an image or video file',
          );
        }
        return;
      }

      final maxSize = isVideoFile ? 50 * 1024 * 1024 : 10 * 1024 * 1024;
      if (fileBytes.length > maxSize) {
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: 'Upload Failed',
            description:
                'File size should be less than ${isVideoFile ? "50MB" : "10MB"}',
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _mediaError = false;
        _isVideo = isVideoFile;
      });

      // 显示预览
      setState(() => _mediaUrl = file.path!);

      try {
        final contentType = isVideoFile
            ? 'video/${file.extension}'
            : 'image/${file.extension}';
        final uploadedUrl = await _uploadService.uploadFile(
          bytes: Uint8List.fromList(fileBytes),
          filename: file.name,
          contentType: contentType,
        );

        setState(() => _mediaUrl = uploadedUrl);
        widget.onUpdate({
          ...widget.card.data.metadata,
          'url': uploadedUrl,
          'content': _markdownContent,
          'tag': _tag,
          'isVideo': isVideoFile,
        });
      } catch (e) {
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: 'Upload Failed',
            description: 'Failed to upload. Please try again.',
          );
        }
        setState(() {
          _mediaError = true;
          _mediaUrl = '';
        });
      } finally {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(
          context: context,
          title: 'Upload Failed',
          description: 'Failed to pick file. Please try again.',
        );
      }
      setState(() => _isUploading = false);
    }
  }

  void _handleMediaRemove() {
    setState(() {
      _mediaUrl = '';
      _isVideo = false;
      _mediaError = false;
    });
    widget.onUpdate({
      ...widget.card.data.metadata,
      'url': '',
      'content': _markdownContent,
      'tag': _tag,
      'isVideo': false,
    });
  }

  Widget _buildTagSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: widget.editable && _isEditingTag
          ? TextField(
              controller: _tagController,
              focusNode: _tagFocusNode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF171717),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) {
                _tagFocusNode.unfocus();
              },
            )
          : GestureDetector(
              onTap: widget.editable
                  ? () {
                      setState(() => _isEditingTag = true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _tagFocusNode.requestFocus();
                      });
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1487FA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _tag,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
    );
  }

  Widget _buildMarkdownSection() {
    return Expanded(
      child: widget.editable && _isEditingMarkdown
          ? TextField(
              controller: _markdownController,
              focusNode: _markdownFocusNode,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF171717)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                hintText:
                    "**This is your title**\n\nthis is your description content, and your **name**, and *more*\n\n`tag`[dinq.me](https://dinq.me)",
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
              ),
            )
          : GestureDetector(
              onTap: widget.editable
                  ? () {
                      setState(() => _isEditingMarkdown = true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markdownFocusNode.requestFocus();
                      });
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _markdownContent.isEmpty
                    ? Center(
                        child: Text(
                          widget.editable
                              ? 'Click to add content'
                              : 'No content yet',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: MarkdownBody(
                          data: _markdownContent,
                          styleSheet: MarkdownStyleSheet(
                            // 段落样式
                            p: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.5,
                            ),
                            pPadding: const EdgeInsets.only(bottom: 4, top: 4),
                            // 移除最后一个段落的底部间距
                            horizontalRuleDecoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.transparent,
                                  width: 0,
                                ),
                              ),
                            ),
                            // 标题样式
                            h1: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            h1Padding: const EdgeInsets.only(bottom: 8, top: 8),
                            h2: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            h2Padding: const EdgeInsets.only(bottom: 8, top: 8),
                            h3: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            h3Padding: const EdgeInsets.only(bottom: 8, top: 8),
                            // 粗体样式
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            // 内联代码样式（会被 builder 覆盖，但保留作为后备）
                            code: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                              backgroundColor: Color(0xFFF3F4F6),
                            ),
                            // 代码块样式
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            codeblockPadding: const EdgeInsets.all(8),
                            // 链接样式（会被 builder 覆盖，但保留作为后备）
                            a: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                              decoration: TextDecoration.none,
                            ),
                            // 列表样式
                            listBullet: const TextStyle(
                              color: Color(0xFF374151),
                            ),
                            listIndent: 24,
                            // 移除最后一个元素的底部间距
                            blockquotePadding: const EdgeInsets.only(left: 16),
                            blockquoteDecoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFFDFDFDF),
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                          builders: {
                            // 自定义内联代码渲染 - 使用 'code' 作为键
                            'code': InlineCodeBuilder(),
                            // 自定义链接渲染 - 使用 'a' 作为键
                            'a': LinkBuilder(),
                          },
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              launchUrl(
                                Uri.parse(href),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _buildMediaSection() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _mediaUrl.isNotEmpty ? null : _handleMediaUpload,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE2E2E2),
              style: BorderStyle.solid,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              if (_mediaUrl.isNotEmpty && !_mediaError)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isVideo
                      ? _buildVideoPlayer()
                      : Image.network(
                          _mediaUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print('MarkdownCard - 图片加载失败');
                            print('MarkdownCard - 失败的URL: $_mediaUrl');
                            print('MarkdownCard - 错误信息: $error');
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _mediaError = true);
                              }
                            });
                            return _buildEmptyMedia();
                          },
                        ),
                )
              else
                _buildEmptyMedia(),
              if (_isUploading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              if (widget.editable && _mediaUrl.isNotEmpty && !_isUploading)
                Positioned.fill(
                  child: MouseRegion(
                    child: GestureDetector(
                      onTap: () {}, // Prevent triggering parent's onTap
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMediaActionButton(
                              icon: Icons.delete,
                              color: Colors.red,
                              onTap: _handleMediaRemove,
                            ),
                            const SizedBox(width: 12),
                            _buildMediaActionButton(
                              icon: _isVideo
                                  ? Icons.videocam
                                  : Icons.camera_alt,
                              color: const Color(0xFF3B82F6),
                              onTap: _handleMediaUpload,
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
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // Note: For full video player functionality, you might want to use video_player package
    // For now, we'll show a placeholder
    return SizedBox.expand(
      child: Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _buildEmptyMedia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isUploading ? Icons.image : Icons.add,
            size: _isUploading ? 40 : 32,
            color: const Color(0xFF636363),
          ),
          const SizedBox(height: 12),
          Text(
            _isUploading
                ? 'Uploading...'
                : (widget.editable ? 'Click to upload' : 'No media'),
            style: const TextStyle(
              color: Color(0xFF303030),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildTagSection(), _buildMarkdownSection()],
            ),
          ),
          const SizedBox(height: 12),
          _buildMediaSection(),
        ],
      ),
    );
  }
}
