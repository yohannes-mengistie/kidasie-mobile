import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/history/reading_history.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../../core/sharing/app_share_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.preferencesStore,
    required this.historyStore,
    required this.onHistoryChanged,
    super.key,
  });

  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final VoidCallback onHistoryChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<double> _textScales = [0.9, 1.0, 1.2, 1.4];

  ReaderPreferences _preferences = const ReaderPreferences(
    language: ReaderLanguage.all,
    textScale: 1,
    highlightSacredNames: true,
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final preferences = await widget.preferencesStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _preferences = preferences;
      _loading = false;
    });
  }

  Future<void> _setLanguage(ReaderLanguage? language) async {
    if (language == null) {
      return;
    }
    setState(() {
      _preferences = _preferences.copyWith(language: language);
    });
    await widget.preferencesStore.saveLanguage(language);
  }

  Future<void> _setTextScale(double sliderValue) async {
    final index = sliderValue.round().clamp(0, _textScales.length - 1);
    final scale = _textScales[index];
    setState(() {
      _preferences = _preferences.copyWith(textScale: scale);
    });
    await widget.preferencesStore.saveTextScale(scale);
  }

  Future<void> _setSacredNames(bool enabled) async {
    setState(() {
      _preferences = _preferences.copyWith(highlightSacredNames: enabled);
    });
    await widget.preferencesStore.saveHighlightSacredNames(enabled);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('የቅርብ ንባብ ይጥፋ?'),
        content: const Text('This removes your recent-reading history only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await widget.historyStore.clear();
    widget.onHistoryChanged();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recent reading cleared.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ቅንብር'),
            Text(
              'Settings',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const _SectionHeader(
                    icon: Icons.chrome_reader_mode_outlined,
                    title: 'የንባብ ቅንብር',
                    subtitle: 'Reader preferences',
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.translate_rounded),
                    title: const Text('ቋንቋ / Language'),
                    subtitle: const Text(
                      'Controls visible text and role names',
                    ),
                    trailing: DropdownButton<ReaderLanguage>(
                      value: _preferences.language,
                      underline: const SizedBox.shrink(),
                      onChanged: _setLanguage,
                      items: ReaderLanguage.values.map((language) {
                        return DropdownMenuItem(
                          value: language,
                          child: Text(_languageLabel(language)),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.format_size_rounded),
                    title: const Text('የፊደል መጠን / Text size'),
                    subtitle: Slider(
                      value: _textScales
                          .indexOf(_preferences.textScale)
                          .toDouble(),
                      min: 0,
                      max: (_textScales.length - 1).toDouble(),
                      divisions: _textScales.length - 1,
                      label: '${(_preferences.textScale * 100).round()}%',
                      onChanged: _setTextScale,
                    ),
                    trailing: Text(
                      '${(_preferences.textScale * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.sacredRed,
                    ),
                    title: const Text('ቅዱሳት ስሞችን በቀይ'),
                    subtitle: const Text('Highlight sacred names in red'),
                    value: _preferences.highlightSacredNames,
                    onChanged: _setSacredNames,
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    icon: Icons.offline_pin_outlined,
                    title: 'ከመስመር ውጭ',
                    subtitle: 'Offline access',
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.download_done_rounded,
                      color: AppTheme.controlGreen,
                    ),
                    title: Text('የእመቤታችን ቅዳሴ ዝግጁ ነው'),
                    subtitle: Text(
                      'The complete St. Mary text is included and available offline.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    icon: Icons.more_horiz_rounded,
                    title: 'ተጨማሪ',
                    subtitle: 'More',
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.ios_share_rounded),
                    title: const Text('መተግበሪያውን ያጋሩ'),
                    subtitle: const Text('Share this app'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => AppShareService.shareApp(),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('የቅርብ ንባብ ያጥፉ'),
                    subtitle: const Text('Clear recent reading'),
                    onTap: _clearHistory,
                  ),
                ],
              ),
      ),
    );
  }

  String _languageLabel(ReaderLanguage language) {
    return switch (language) {
      ReaderLanguage.all => 'ሁሉም',
      ReaderLanguage.geez => 'ግዕዝ',
      ReaderLanguage.amharic => 'አማርኛ',
      ReaderLanguage.english => 'English',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.liturgicalGold),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
