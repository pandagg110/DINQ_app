import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → 开发者 → API Keys。1:1 还原 web `ApiKeysCard.tsx`：
/// 头部「API keys」+ 说明 + Create；每行 名称(+Disabled 徽章) / 掩码 key(eye 切换) /
/// Created 日期 / eye·copy·trash 三操作；创建命名弹窗；复制弹窗(MCP URL + API key)；
/// 删除二次确认。接口走 AccountService（/api-keys）。
class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({super.key});

  @override
  State<ApiKeysPage> createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  final _service = AccountService();
  List<dynamic> _keys = [];
  final Set<String> _visible = {};
  final Map<String, String> _fullKeys = {}; // 创建时拿到的完整 key
  bool _loading = true;
  String? _error;

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

  // 与 web utils/apiKey.ts maskApiKey 对齐
  String _mask(String? key) {
    final v = key?.trim() ?? '';
    if (v.isEmpty) return 'YOUR_API_KEY';
    if (v == 'YOUR_API_KEY' || v.contains('*')) return v;
    if (v.length <= 8) return '****';
    if (v.length <= 12) return '${v.substring(0, 4)}****';
    return '${v.substring(0, 8)}****${v.substring(v.length - 4)}';
  }

  String _mcpUrl(String key) => 'https://search.dinq.me/u/$key/mcp';

  String _fmtDate(String? s) {
    final d = DateTime.tryParse(s ?? '')?.toLocal();
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _idOf(Map<String, dynamic> k) => (k['id'] ?? '').toString();
  String _keyOf(Map<String, dynamic> k) =>
      _fullKeys[_idOf(k)] ?? (k['api_key'] ?? k['key'] ?? '').toString();

  Future<void> _create() async {
    final name = await _showCreateDialog();
    if (name == null || name.trim().isEmpty) return;
    try {
      final created = await _service.createApiKey(name.trim());
      final id = (created['id'] ?? '').toString();
      final fullKey = (created['api_key'] ?? created['key'] ?? '').toString();
      if (id.isNotEmpty && fullKey.isNotEmpty) _fullKeys[id] = fullKey;
      _snack('API key created');
      await _load();
      if (mounted) _showCopyDialog(Map<String, dynamic>.from(created));
    } catch (e) {
      _snack('Create failed: $e');
    }
  }

  Future<String?> _showCreateDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Create API Key',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF171717))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Key Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF171717))),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Production Key',
                hintStyle: const TextStyle(color: Color(0xFF9E9B93)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF171717)),
                ),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6862))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF171717),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCopyDialog(Map<String, dynamic> k) {
    final key = _keyOf(k);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Copy API Key',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF171717))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copyBlock('Remote MCP server URL', 'For Codex, Claude and other MCP clients',
                _mcpUrl(key)),
            const SizedBox(height: 16),
            _copyBlock('API key', 'For programmatic API access', key),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Color(0xFF171717))),
          ),
        ],
      ),
    );
  }

  Widget _copyBlock(String title, String sub, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF171717))),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF737373))),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                _snack('Copied');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD8D8D8)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: Color(0xFF171717)),
                    SizedBox(width: 4),
                    Text('Copy',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF171717))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(value,
              style: const TextStyle(
                  fontSize: 12, fontFamily: 'monospace', color: Color(0xFF737373))),
        ),
      ],
    );
  }

  Future<void> _delete(Map<String, dynamic> k) async {
    final name = (k['name'] ?? 'this key').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete API Key',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF171717))),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6862))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6862))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteApiKey(int.tryParse(_idOf(k)) ?? 0);
      _snack('API key deleted');
      await _load();
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'API Keys'),
      body: _body(),
    );
  }

  Widget _body() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 头部：标题 + 说明 + Create
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API keys',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF171717))),
                  SizedBox(height: 4),
                  Text('Create and manage API keys for DINQ integrations.',
                      style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF8A8880))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _create,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Create',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(color: DinqTokens.textTertiary)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (_keys.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.vpn_key_outlined, size: 48, color: Color(0xFFCDCDCD)),
                  SizedBox(height: 12),
                  Text('No API keys yet', style: TextStyle(fontSize: 14, color: Color(0xFFA3A3A3))),
                ],
              ),
            ),
          )
        else
          for (final k in _keys) _keyRow(Map<String, dynamic>.from(k as Map)),
      ],
    );
  }

  Widget _keyRow(Map<String, dynamic> k) {
    final id = _idOf(k);
    final name = (k['name'] ?? 'Key').toString();
    final isActive = k['is_active'] != false;
    final visible = _visible.contains(id);
    final display = visible ? _keyOf(k) : _mask(_keyOf(k));
    final created = _fmtDate(k['created_at']?.toString());

    return Opacity(
      opacity: isActive ? 1 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF171717))),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Disabled',
                              style: TextStyle(fontSize: 11, color: Color(0xFF737373))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace', color: Color(0xFF737373))),
                  if (created.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Created $created',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFA3A3A3))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _iconBtn(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                () => setState(() => visible ? _visible.remove(id) : _visible.add(id))),
            _iconBtn(Icons.copy_rounded, () => _showCopyDialog(k)),
            _iconBtn(Icons.delete_outline, () => _delete(k)),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: const Color(0xFF737373)),
      ),
    );
  }
}
