import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/account_service.dart';
import '../../utils/top_toast_util.dart';

/// 组织邀请弹层，对齐 web InviteOrgModal.tsx：
/// - 标题「Invite to organization」+ 右上关闭（web AdaptiveModal 标题栏）
/// - QR 码 200、前景 #171717、白底、rounded-2xl + #EEEDE9 描边框（tsx:99-107）
/// - 「Invite link」标签 + 只读链接框 + 复制按钮（tsx:110-132）
/// - 底部操作：Regenerate invite link（仅 admin/owner，二次确认后刷新，
///   tsx:66-87 + 136-148）与 Download PNG（tsx:48-64 + 149-156）。
///   QA 备注：两个按钮等分（web 是 justify-between，App 按 QA 标注等分）。
/// - 链接格式对齐 web：{origin}/join/{invite_code}，小写原样（tsx:33-36）。
/// - Download PNG：640px、白底、前景 #171717、文件名 {slug}-invite-qr.png
///   （tsx:52-59）；App 侧落地为生成 PNG 后走系统分享/保存面板。
class InviteOrgSheet extends StatefulWidget {
  const InviteOrgSheet({
    super.key,
    required this.orgId,
    required this.slug,
    required this.inviteCode,
    required this.canRefresh,
    this.onInviteCodeChange,
  });

  final String orgId;
  final String slug;
  final String inviteCode;
  final bool canRefresh;
  final ValueChanged<String>? onInviteCodeChange;

  static Future<void> show(
    BuildContext context, {
    required String orgId,
    required String slug,
    required String inviteCode,
    required bool canRefresh,
    ValueChanged<String>? onInviteCodeChange,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteOrgSheet(
        orgId: orgId,
        slug: slug,
        inviteCode: inviteCode,
        canRefresh: canRefresh,
        onInviteCodeChange: onInviteCodeChange,
      ),
    );
  }

  @override
  State<InviteOrgSheet> createState() => _InviteOrgSheetState();
}

class _InviteOrgSheetState extends State<InviteOrgSheet> {
  static const _ink = Color(0xFF171717);
  static const _muted = Color(0xFF6B6862);
  static const _border = Color(0xFFEEEDE9);

  final _service = AccountService();
  late String _code = widget.inviteCode;
  bool _refreshing = false;
  bool _downloading = false;

  /// 对齐 web inviteUrl（InviteOrgModal.tsx:33-36）：/join/{code}，不改大小写。
  String get _inviteUrl => 'https://dinq.me/join/$_code';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _inviteUrl));
    if (!mounted) return;
    TopToastUtil.showSuccess(
        context: context, title: 'Invite link copied', description: '');
  }

  /// 刷新邀请码：先二次确认（web useConfirmDialog danger 变体，
  /// InviteOrgModal.tsx:66-87），确认后 POST refresh-invite。
  Future<void> _confirmRegenerate() async {
    if (_refreshing) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Refresh invite link?',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
        content: const Text(
            'The current link and QR code will stop working immediately. '
            'Share the new ones afterwards.',
            style: TextStyle(fontSize: 14, color: _muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Refresh',
                  style: TextStyle(
                      color: Color(0xFFDC2626), fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _refreshing = true);
    try {
      final code = await _service.refreshOrgInvite(widget.orgId);
      if (!mounted) return;
      if (code.isNotEmpty) {
        setState(() => _code = code);
        widget.onInviteCodeChange?.call(code);
      }
      TopToastUtil.showSuccess(
          context: context, title: 'Invite link refreshed', description: '');
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
            context: context, title: 'Refresh failed', description: '');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// 生成 640px 白底 QR PNG（对齐 web QRCode.toDataURL width 640 / margin 2 /
  /// dark #171717 / light #ffffff，InviteOrgModal.tsx:52-56）。
  Future<Uint8List> _buildQrPng() async {
    const double size = 640;
    const double margin = 40;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, size, size), Paint()..color = Colors.white);
    canvas.translate(margin, margin);
    QrPainter(
      data: _inviteUrl,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _ink),
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: _ink),
    ).paint(canvas, const Size(size - margin * 2, size - margin * 2));
    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// iOS（尤其 iPad）分享面板必须提供锚点矩形，否则 share_plus 会抛
  /// sharePositionOrigin 异常（同 shortlist_page.dart 的兜底做法）。
  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// 下载 QR PNG：文件名 {slug}-invite-qr.png（web InviteOrgModal.tsx:59）；
  /// 移动端没有浏览器下载，落地为写临时文件后唤起系统分享/保存。
  Future<void> _downloadPng() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await _buildQrPng();
      final dir = await getTemporaryDirectory();
      final slug = widget.slug.isNotEmpty ? widget.slug : 'organization';
      final file = File('${dir.path}/$slug-invite-qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '$slug-invite-qr.png',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
            context: context,
            title: 'Failed to generate QR code',
            description: '');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏（web AdaptiveModal：标题 + 右上 X）
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Invite to organization',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20, color: _muted),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // QR 码：白底描边卡片（web rounded-2xl border-[#EEEDE9] p-4）
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: QrImageView(
                  data: _inviteUrl,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  size: 200,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  gapless: true,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: _ink),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: _ink),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 链接行（web invite.linkLabel + 只读输入框 + 复制按钮）
            const Text('Invite link',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Text(_inviteUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _muted)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _copy,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child:
                        const Icon(Icons.copy_rounded, size: 16, color: _muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 操作行：Regenerate（仅管理员）+ Download PNG，等分（QA 标注）
            Row(
              children: [
                if (widget.canRefresh) ...[
                  Expanded(
                    child: _actionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Regenerate invite link',
                      onTap: _confirmRegenerate,
                      busy: _refreshing,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _actionButton(
                    icon: Icons.file_download_outlined,
                    label: 'Download PNG',
                    onTap: _downloadPng,
                    busy: _downloading,
                    primary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 操作按钮（web h-9 rounded-lg text-xs font-medium；主按钮黑底白字，
  /// 次按钮白底 #EEEDE9 描边 #6b6862 字色）。
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
    bool busy = false,
  }) {
    final fg = primary ? Colors.white : _muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: _border),
        ),
        child: busy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: fg),
                    const SizedBox(width: 6),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: fg)),
                  ],
                ),
              ),
      ),
    );
  }
}
