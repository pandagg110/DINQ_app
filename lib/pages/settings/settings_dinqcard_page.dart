import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/settings_store.dart';

class SettingsDinqCardPage extends StatelessWidget {
  const SettingsDinqCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('DINQ Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Color Theme', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: ColorTheme.values.map((theme) {
                final isSelected = settings.colorTheme == theme;
                return ChoiceChip(
                  label: Text(theme.name),
                  selected: isSelected,
                  onSelected: (_) => settings.setColorTheme(theme),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

