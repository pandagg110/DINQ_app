import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/resume_models.dart';

/// 对齐 Web `ResumePreview` / `ResumeList` lucide-react 图标。
abstract final class ResumeIcons {
  static const _base = 'assets/icons/mydinq/resume';
  static const chevronDown = '$_base/chevron-down.svg';
  static const download = '$_base/download.svg';
  static const panelLeftClose = '$_base/panel-left-close.svg';
  static const panelLeftOpen = '$_base/panel-left-open.svg';
  static const upload = '$_base/upload.svg';
  static const zoomIn = '$_base/zoom-in.svg';
  static const zoomOut = '$_base/zoom-out.svg';
  static const fileText = '$_base/file-text.svg';
  static const check = '$_base/check.svg';
  static const fileInput = '$_base/file-input.svg';
  static const moreHorizontal = '$_base/more-horizontal.svg';
  static const pencil = '$_base/pencil.svg';
  static const plus = '$_base/plus.svg';
  static const trash2 = '$_base/trash-2.svg';
  static const resumeEmpty = '$_base/resume-empty.svg';
  static const resumeUploading = '$_base/resume-uploading.svg';
}

class ResumeSvgIcon extends StatelessWidget {
  const ResumeSvgIcon(
    this.asset, {
    super.key,
    this.size = 16,
    this.color = const Color(0xFF2C2B2A),
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

String resumeFormatTimeAgo(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return '';
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
  if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'just now';
}

String resumeRowSubtitle(ResumeItem item) {
  final t = resumeFormatTimeAgo(item.updatedAt) != ''
      ? resumeFormatTimeAgo(item.updatedAt)
      : resumeFormatTimeAgo(item.createdAt);
  final status = resumeStatusLabel(item.status);
  return t.isNotEmpty ? '$status · $t' : status;
}
