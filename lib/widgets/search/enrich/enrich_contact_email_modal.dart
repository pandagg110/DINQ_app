import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../services/connector_service.dart';
import '../../../services/outreach_service.dart';
import '../../../utils/email_parse_util.dart';

typedef MessageTone = String; // friendly | professional | concise

const _toneOptions = <({String value, String label, Color color})>[
  (value: 'friendly', label: 'Friendly', color: Color(0xFF22C55E)),
  (value: 'professional', label: 'Professional', color: Color(0xFF6366F1)),
  (value: 'concise', label: 'Concise', color: Color(0xFFF97316)),
];

const _cText = Color(0xFF2A2826);
const _cMuted = Color(0xFF9E9B93);
const _cBorder = Color(0xFFF0EEEA);
const _cToneBar = Color(0xFFF5F4F0);
const _cPlaceholder = Color(0xFFC5C2BC);
const _cChipBorder = Color(0xFFE5E2DC);

/// 对齐 Web `ContactEmailModal`（EnrichProfileView.tsx）。
class EnrichContactEmailModal extends StatefulWidget {
  const EnrichContactEmailModal({
    super.key,
    required this.recipientEmail,
    required this.recipientName,
    this.recipientTitle,
    this.favoriteId,
  });

  final String recipientEmail;
  final String recipientName;
  final String? recipientTitle;
  final String? favoriteId;

  static Future<void> show(
    BuildContext context, {
    required String recipientEmail,
    required String recipientName,
    String? recipientTitle,
    String? favoriteId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: EnrichContactEmailModal(
          recipientEmail: recipientEmail,
          recipientName: recipientName,
          recipientTitle: recipientTitle,
          favoriteId: favoriteId,
        ),
      ),
    );
  }

  @override
  State<EnrichContactEmailModal> createState() =>
      _EnrichContactEmailModalState();
}

class _EnrichContactEmailModalState extends State<EnrichContactEmailModal> {
  final _outreach = OutreachService();
  final _connector = ConnectorService();
  final _emailSettings = EmailSettingsService();

  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();

  String _tone = 'friendly';
  String _channel = 'email';
  bool _generating = false;
  bool _sending = false;
  bool _sent = false;
  DateTime? _sentAt;
  late String _selectedEmail;
  ConnectorAccount? _emailAccount;
  EmailSetting? _senderSetting;

  bool get _emailConnected => _emailAccount != null;

  @override
  void initState() {
    super.initState();
    _selectedEmail = parseEmails(widget.recipientEmail).firstOrNull ?? '';
    _loadAccounts();
    _generateMessage('friendly');
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _connector.getAccounts();
      final emailAccount = accounts.cast<ConnectorAccount?>().firstWhere(
            (a) =>
                a != null &&
                a.status == 'active' &&
                (a.platform == 'gmail' ||
                    a.platform == 'microsoft' ||
                    a.platform == 'imap'),
            orElse: () => null,
          );
      final settings = await _emailSettings.list();
      if (!mounted) return;
      EmailSetting? sender;
      if (emailAccount?.accountEmail != null) {
        for (final s in settings) {
          if (s.email == emailAccount!.accountEmail) {
            sender = s;
            break;
          }
        }
      }
      setState(() {
        _emailAccount = emailAccount;
        _senderSetting = sender;
        if (emailAccount != null) _channel = 'user_email';
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _generateMessage(String tone) async {
    setState(() {
      _generating = true;
      _tone = tone;
      _subjectController.clear();
      _contentController.clear();
    });
    try {
      final displayName = _senderSetting?.displayName;
      final title = widget.recipientTitle;
      final contextText =
          '${displayName != null ? 'My name is $displayName. ' : ''}'
          'I want to reach out to ${widget.recipientName}'
          '${title != null ? ', $title' : ''} (${widget.recipientEmail}).';
      final res = await _outreach.generate(userContext: contextText, style: tone);
      if (!mounted) return;
      _contentController.text = res['body']?.toString() ?? '';
      _subjectController.text = res['subject']?.toString() ?? '';
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate message')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _send() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final signature = _senderSetting?.signature;
      final finalContent = signature != null && signature.isNotEmpty
          ? '$content\n\n-- \n$signature'
          : content;
      await _outreach.contact(
        type: _channel,
        email: _selectedEmail,
        subject: _subjectController.text.trim().isEmpty
            ? 'Hello from DINQ'
            : _subjectController.text.trim(),
        content: finalContent,
        senderEmail: _emailAccount?.accountEmail,
        senderName: _senderSetting?.displayName,
        favoriteId: widget.favoriteId,
      );
      if (!mounted) return;
      setState(() {
        _sent = true;
        _sentAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: _selectedEmail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  Future<void> _pickRecipient(List<String> emails) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select recipient email',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: _cPlaceholder,
                  ),
                ),
                const SizedBox(height: 8),
                for (final email in emails) ...[
                  _RecipientOption(
                    email: email,
                    active: email == _selectedEmail,
                    onTap: () => Navigator.pop(ctx, email),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedEmail = picked);
    }
  }

  Future<void> _showIntegrationPrompt({required bool changing}) async {
    final title = changing ? 'Change sender email' : 'Connect email account';
    final body = changing
        ? 'To change sender email, go to the Integration page. Redirect now?'
        : 'Connect your email to send this cold email from your own address.';

    final go = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _cText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor: _cText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: _cChipBorder),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _cText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Integration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (go == true && mounted) {
      Navigator.pop(context);
      context.push('/me/integration');
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEmails = parseEmails(widget.recipientEmail);
    final canSend = !_sent &&
        !_sending &&
        !_generating &&
        _contentController.text.trim().isNotEmpty &&
        _emailConnected;

    // 固定高度：Header + From/To/Subject 固定，仅正文区滚动（红框范围）
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.9;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: [
          _buildHeader(),
          _buildFromRow(),
          _buildToRow(allEmails),
          _buildSubjectRow(),
          Expanded(child: _buildBody()),
          _buildFooter(canSend),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _sent ? 'Sent' : 'Outreach Email',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _cText,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              hoverColor: _cToneBar,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.close, size: 18, color: _cMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledRow({
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: _cMuted),
            ),
          ),
          Expanded(child: child),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildFromRow() {
    return _buildLabeledRow(
      label: 'From',
      child: Text(
        _emailAccount?.accountEmail ?? 'Not connected',
        style: const TextStyle(fontSize: 14, color: _cText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _sent
          ? null
          : TextButton(
              onPressed: () => _showIntegrationPrompt(
                changing: _emailConnected,
              ),
              style: TextButton.styleFrom(
                foregroundColor: _cMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _emailConnected ? 'Change' : 'Connect',
                style: const TextStyle(fontSize: 12, color: _cMuted),
              ),
            ),
    );
  }

  Widget _buildToRow(List<String> allEmails) {
    return _buildLabeledRow(
      label: 'To',
      child: allEmails.length > 1
          ? GestureDetector(
              onTap: _sent ? null : () => _pickRecipient(allEmails),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _selectedEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: _cText,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9F0E3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${allEmails.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2A7D5A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 14, color: _cMuted),
                ],
              ),
            )
          : Text(
              _selectedEmail,
              style: const TextStyle(fontSize: 14, color: _cText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: IconButton(
        onPressed: _copyEmail,
        icon: const Icon(Icons.copy_outlined, size: 16, color: _cPlaceholder),
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        splashRadius: 16,
      ),
    );
  }

  Widget _buildSubjectRow() {
    return _buildLabeledRow(
      label: 'Subject',
      child: TextField(
        controller: _subjectController,
        enabled: !_generating && !_sent,
        style: TextStyle(
          fontSize: 14,
          color: _generating && !_sent ? _cMuted : _cText,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: _generating ? '...' : 'Enter subject...',
          hintStyle: const TextStyle(fontSize: 14, color: _cPlaceholder),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 仅正文可滚动；语气条叠在正文区底部（对齐 web absolute bottom）
    // Scrollbar 贴弹窗右边：外层不加水平 padding，正文自己缩进
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16, bottom: _sent ? 16 : 48),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _contentController,
                scrollController: _scrollController,
                enabled: !_generating && !_sent,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: _generating ? Colors.transparent : _cText,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: _generating ? null : 'Write your message...',
                  hintStyle:
                      const TextStyle(fontSize: 14, color: _cPlaceholder),
                ),
              ),
            ),
          ),
        ),
        if (_generating)
          const Positioned(
            top: 16,
            left: 24,
            child: Text(
              'Composing...',
              style: TextStyle(fontSize: 14, color: _cMuted),
            ),
          ),
        if (!_sent)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(child: _buildToneSelector()),
          ),
      ],
    );
  }

  Widget _buildToneSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cToneBar,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opt in _toneOptions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: _tone == opt.value ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: _generating ? null : () => _generateMessage(opt.value),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _tone == opt.value
                            ? _cChipBorder
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: opt.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _tone == opt.value
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: _tone == opt.value ? _cText : _cMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool canSend) {
    final timeLabel = _sentAt == null
        ? null
        : 'Sent at ${TimeOfDay.fromDateTime(_sentAt!).format(context)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                timeLabel ?? '',
                style: const TextStyle(fontSize: 12, color: _cMuted),
              ),
            ),
            if (_sent)
              _PrimaryActionButton(
                label: 'Close',
                onPressed: () => Navigator.pop(context),
              )
            else
              _PrimaryActionButton(
                label: _sending
                    ? 'Sending...'
                    : _generating
                        ? 'Generating...'
                        : 'Send',
                loading: _sending || _generating,
                showSendIcon: !_sending && !_generating,
                onPressed: canSend ? _send : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.showSendIcon = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool showSendIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2826),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: onPressed == null && !loading ? 0.4 : 1,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (showSendIcon) ...[
                  const Icon(Icons.send, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipientOption extends StatelessWidget {
  const _RecipientOption({
    required this.email,
    required this.active,
    required this.onTap,
  });

  final String email;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : const Color(0xFFF7F6F2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? _cText : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: active ? _cText : _cMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: active ? _cText : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? _cText : const Color(0xFFD9D6D0),
                  ),
                ),
                child: active
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
