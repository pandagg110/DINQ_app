import 'package:flutter/material.dart';

import '../../../services/connector_service.dart';
import '../../../services/outreach_service.dart';

typedef MessageTone = String; // friendly | professional | concise

const _toneOptions = <({String value, String label, Color color})>[
  (value: 'friendly', label: 'Friendly', color: Color(0xFF22C55E)),
  (value: 'professional', label: 'Professional', color: Color(0xFF6366F1)),
  (value: 'concise', label: 'Concise', color: Color(0xFFF97316)),
];

List<String> parseEmails(String raw) {
  return raw
      .split(RegExp(r'[,;\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// 对齐 Web `ContactEmailModal`（冷邮件撰写）。
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

  String _tone = 'friendly';
  String _channel = 'email';
  bool _generating = false;
  bool _sending = false;
  bool _sent = false;
  late String _selectedEmail;
  ConnectorAccount? _emailAccount;
  EmailSetting? _senderSetting;

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
      setState(() => _sent = true);
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

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEmails = parseEmails(widget.recipientEmail);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E3DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _sent ? 'Message sent' : 'Send cold email',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2826),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.recipientName,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
            ),
            const SizedBox(height: 16),
            if (allEmails.length > 1)
              DropdownButtonFormField<String>(
                value: _selectedEmail,
                decoration: const InputDecoration(labelText: 'Recipient'),
                items: allEmails
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedEmail = v);
                },
              )
            else
              Text(
                _selectedEmail,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9E9A94)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final opt in _toneOptions)
                  ChoiceChip(
                    label: Text(opt.label),
                    selected: _tone == opt.value,
                    onSelected: (_) => _generateMessage(opt.value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: 'Message',
                border: const OutlineInputBorder(),
                suffixIcon: _generating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _sent || _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2B2A),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_sent ? 'Sent' : 'Send'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
