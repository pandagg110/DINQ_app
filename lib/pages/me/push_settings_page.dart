import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → 推送设置（Notion「消息推送 / 推送设置」P1）。
/// 私信 / Radar / 系统通知 三个开关。
/// web H5 无推送、无后端偏好接口，故先本地持久化(shared_preferences)；
/// 待后端提供通知偏好接口后改为同步服务端。
class PushSettingsPage extends StatefulWidget {
  const PushSettingsPage({super.key});

  @override
  State<PushSettingsPage> createState() => _PushSettingsPageState();
}

class _PushSettingsPageState extends State<PushSettingsPage> {
  static const _kDm = 'push.dm';
  static const _kRadar = 'push.radar';
  static const _kSystem = 'push.system';

  bool _dm = true;
  bool _radar = true;
  bool _system = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dm = p.getBool(_kDm) ?? true;
      _radar = p.getBool(_kRadar) ?? true;
      _system = p.getBool(_kSystem) ?? true;
      _loading = false;
    });
  }

  Future<void> _set(String key, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Push notifications'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, left: 4),
                  child: Text(
                    'Choose which notifications are pushed to your device.',
                    style: TextStyle(fontSize: 13, color: DinqTokens.textSecondary),
                  ),
                ),
                _card([
                  _row('Direct messages', 'New private messages', _dm, (v) {
                    setState(() => _dm = v);
                    _set(_kDm, v);
                  }),
                  _divider(),
                  _row('Talent Radar', 'New candidates from your radars', _radar, (v) {
                    setState(() => _radar = v);
                    _set(_kRadar, v);
                  }),
                  _divider(),
                  _row('System notifications', 'Product and account updates', _system, (v) {
                    setState(() => _system = v);
                    _set(_kSystem, v);
                  }),
                ]),
              ],
            ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _row(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 12, color: DinqTokens.textTertiary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
