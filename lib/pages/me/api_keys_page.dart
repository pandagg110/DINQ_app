import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → 开发者 → API Keys。接 /api-keys（list/create/delete）。
class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({super.key});

  @override
  State<ApiKeysPage> createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  final _service = AccountService();
  List<dynamic> _keys = [];
  bool _loading = true;
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final keys = await _service.getApiKeys();
      if (!mounted) return;
      setState(() {
        _keys = keys;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final created = await _service.createApiKey('Mobile key');
      if (!mounted) return;
      // 新建的 key 通常只在创建时返回明文，弹窗展示
      final secret = (created['key'] ?? created['secret'] ?? created['api_key'] ?? '')
          .toString();
      if (secret.isNotEmpty) {
        await _showSecret(secret);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showSecret(String secret) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('API Key created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy it now — it won\'t be shown again.'),
            const SizedBox(height: 12),
            SelectableText(secret,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: secret));
              Navigator.of(context).pop();
            },
            child: const Text('Copy & close'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    try {
      await _service.deleteApiKey(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'API Keys'),
      body: _body(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _create,
        backgroundColor: ColorUtil.textColor,
        foregroundColor: Colors.white,
        icon: _creating
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add, size: 20),
        label: const Text('New key'),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: DinqTokens.textTertiary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_keys.isEmpty) {
      return const Center(
        child: Text('No API keys yet',
            style: TextStyle(color: DinqTokens.textTertiary)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (final k in _keys) _keyRow(Map<String, dynamic>.from(k as Map)),
      ],
    );
  }

  Widget _keyRow(Map<String, dynamic> k) {
    final id = (k['id'] as num?)?.toInt() ?? 0;
    final name = (k['name'] ?? 'API key').toString();
    final preview = (k['key_preview'] ?? k['preview'] ?? k['masked'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Text(name,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(preview,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace', color: DinqTokens.textTertiary)),
                ],
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _delete(id),
            child: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE24B3C)),
          ),
        ],
      ),
    );
  }
}
