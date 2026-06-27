import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/connector_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/api_error.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → 开发者 → Integration。1:1 还原 web integration/page.tsx：
/// Section1 Email integration（未连接 → Gmail/Microsoft/IMAP 连接卡 OAuth；
/// 已连接 → 邮箱卡含 状态点 / 编辑(发件人·签名) / 断开）；
/// Section2 API access（People Search API / DINQ Search Skill / Remote MCP Connector）。
class IntegrationPage extends StatefulWidget {
  const IntegrationPage({super.key});

  @override
  State<IntegrationPage> createState() => _IntegrationPageState();
}

class _IntegrationPageState extends State<IntegrationPage> {
  final _connector = ConnectorService();
  final _emailSettings = EmailSettingsService();

  List<ConnectorAccount> _accounts = [];
  List<EmailSetting> _settings = [];
  bool _loading = true;

  static const _ink = Color(0xFF2A2826);
  static const _muted = Color(0xFF9E9B93);
  static const _callbackUrl = 'https://dinq.me/integration';

  static const _connectors = [
    {'platform': 'gmail', 'title': 'Gmail', 'subtitle': 'gmail.com', 'button': 'Sign in with Gmail'},
    {'platform': 'microsoft', 'title': 'Microsoft', 'subtitle': 'outlook.com', 'button': 'Sign in with Microsoft'},
    {'platform': 'imap', 'title': 'IMAP', 'subtitle': 'Internet Message Access Protocol', 'button': 'Sign in with IMAP'},
  ];

  static const _apiCards = [
    {'title': 'People Search API', 'subtitle': 'Try live API requests and inspect SDK examples.', 'action': 'Open API', 'href': 'https://dinq.me/api-playground#api'},
    {'title': 'DINQ Search Skill', 'subtitle': 'Copy the agent skill for DINQ remote MCP search.', 'action': 'Open Skill', 'href': 'https://dinq.me/api-playground#skill'},
    {'title': 'Remote MCP Connector', 'subtitle': 'Copy the MCP server URL for Codex, Claude, and other MCP clients.', 'action': 'Open MCP', 'href': 'https://dinq.me/api-playground#mcp'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _connector.getAccounts(),
        _emailSettings.list(),
      ]);
      if (!mounted) return;
      setState(() {
        _accounts = results[0] as List<ConnectorAccount>;
        _settings = results[1] as List<EmailSetting>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  EmailSetting? _settingFor(String email) {
    for (final s in _settings) {
      if (s.email == email) return s;
    }
    return null;
  }

  Future<void> _connect(String platform) async {
    try {
      final url = await _connector.initiateConnect(platform, _callbackUrl);
      if (url != null && url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _snack('Connect failed: $e');
    }
  }

  Future<void> _disconnect(ConnectorAccount a) async {
    try {
      await _connector.disconnect(a.id);
      await _load();
    } catch (e) {
      _snack('Disconnect failed: $e');
    }
  }

  Future<void> _openLink(String href) async {
    await launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Integration'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _sectionHeading('Email integration',
                    'Connect your email accounts to send automated sequences.'),
                const SizedBox(height: 16),
                if (_accounts.isEmpty)
                  for (final c in _connectors) _connectorCard(c)
                else
                  for (final a in _accounts) _connectedCard(a),
                const SizedBox(height: 28),
                _sectionHeading('API access',
                    'Integrate DINQ search APIs into your own workflows.'),
                const SizedBox(height: 16),
                for (final c in _apiCards) _apiCard(c),
              ],
            ),
    );
  }

  Widget _sectionHeading(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _ink)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 14, height: 1.4, color: _muted)),
      ],
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'gmail':
        return Icons.mail_outline_rounded;
      case 'microsoft':
        return Icons.alternate_email_rounded;
      case 'imap':
        return Icons.dns_outlined;
      default:
        return Icons.email_outlined;
    }
  }

  Widget _connectorCard(Map<String, String> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DinqTokens.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_platformIcon(c['platform']!), size: 20, color: _ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['title']!,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                    Text(c['subtitle']!,
                        style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _connect(c['platform']!),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E0D9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(c['button']!,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: _ink)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectedCard(ConnectorAccount a) {
    final expired = a.status == 'expired';
    final setting = _settingFor(a.accountEmail ?? '');
    final sender = setting?.displayName;
    final signature = setting?.signature;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EEE8),
                  shape: BoxShape.circle,
                ),
                child: Icon(_platformIcon(a.platform), size: 20, color: _ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.accountEmail ?? a.platform,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: expired ? const Color(0xFFC4702A) : const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(expired ? 'Token expired' : 'Connected',
                            style: TextStyle(
                                fontSize: 12,
                                color: expired ? const Color(0xFFC4702A) : const Color(0xFF22C55E))),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: _muted),
                onSelected: (v) {
                  if (v == 'edit') _editEmailSetting(a, setting);
                  if (v == 'disconnect') _disconnect(a);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'edit',
                      child: Text(setting == null ? 'Set up settings' : 'Edit settings')),
                  const PopupMenuItem(
                      value: 'disconnect',
                      child: Text('Disconnect', style: TextStyle(color: Color(0xFF9A6A44)))),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _kv('Sender', sender, emptyText: 'Not set'),
          const SizedBox(height: 10),
          _kv('Signature', signature, emptyText: 'Signature not set', emptyWarn: true),
        ],
      ),
    );
  }

  Widget _kv(String label, String? value, {required String emptyText, bool emptyWarn = false}) {
    final has = value != null && value.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFFB5A08A))),
        ),
        Expanded(
          child: has
              ? Text(value, style: const TextStyle(fontSize: 14, color: _ink))
              : Row(
                  children: [
                    if (emptyWarn) ...[
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFC4702A)),
                      const SizedBox(width: 4),
                    ],
                    Text(emptyText,
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: emptyWarn ? FontStyle.normal : FontStyle.italic,
                            color: emptyWarn ? const Color(0xFFC4702A) : _muted)),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _editEmailSetting(ConnectorAccount a, EmailSetting? setting) async {
    final isCreate = setting == null;
    // 新建场景需要 platform → emailType 的映射；不支持的平台直接提示。
    final emailType = EmailSettingsService.emailTypeForPlatform(a.platform);
    if (isCreate && emailType == null) {
      _snack('Unsupported platform for email settings');
      return;
    }
    final senderCtrl = TextEditingController(text: setting?.displayName ?? '');
    final sigCtrl = TextEditingController(text: setting?.signature ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isCreate ? 'Set up email settings' : 'Edit email settings',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sender',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ink)),
            const SizedBox(height: 6),
            TextField(
              controller: senderCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            const Text('Signature',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ink)),
            const SizedBox(height: 6),
            TextField(
              controller: sigCtrl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (isCreate) {
        await _emailSettings.create(
          emailType: emailType!,
          email: a.accountEmail ?? '',
          displayName: senderCtrl.text,
          signature: sigCtrl.text,
        );
      } else {
        await _emailSettings.update(setting.id,
            displayName: senderCtrl.text, signature: sigCtrl.text);
      }
      await _load();
    } catch (e) {
      _snack('Save failed: ${apiErrorMessage(e)}');
    }
  }

  Widget _apiCard(Map<String, String> c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLink(c['href']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DinqTokens.borderLL),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['title']!,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 4),
                  Text(c['subtitle']!,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: _muted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(c['action']!,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: _ink),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
