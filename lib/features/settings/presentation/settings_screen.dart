import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/history/reading_history.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../../core/sharing/app_share_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.preferencesStore,
    required this.historyStore,
    required this.appLanguage,
    required this.onAppLanguageChanged,
    required this.onHistoryChanged,
    super.key,
  });

  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final AppLanguage appLanguage;
  final ValueChanged<AppLanguage> onAppLanguageChanged;
  final VoidCallback onHistoryChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<double> _textScales = [0.9, 1.0, 1.2, 1.4];

  ReaderPreferences _preferences = const ReaderPreferences(
    appLanguage: AppLanguage.amharic,
    language: ReaderLanguage.all,
    textScale: 1,
    highlightSacredNames: true,
  );
  bool _loading = true;
  bool _sharingApk = false;

  AppLanguage get _appLanguage => widget.appLanguage;

  String _ui({required String amharic, required String english}) {
    return _appLanguage.text(amharic: amharic, english: english);
  }

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

  void _setAppLanguage(Set<AppLanguage> selection) {
    if (selection.isEmpty) {
      return;
    }
    final language = selection.first;
    setState(() {
      _preferences = _preferences.copyWith(appLanguage: language);
    });
    widget.onAppLanguageChanged(language);
  }

  Future<void> _setReaderLanguage(ReaderLanguage? language) async {
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

  Future<void> _shareApk() async {
    if (_sharingApk) {
      return;
    }
    setState(() {
      _sharingApk = true;
    });
    try {
      await AppShareService.shareApp();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ui(
                amharic: 'የAPK ፋይሉን ማጋራት አልተቻለም።',
                english: 'The APK file could not be shared.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharingApk = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _ui(amharic: 'የቅርብ ንባብ ይጥፋ?', english: 'Clear recent reading?'),
        ),
        content: Text(
          _ui(
            amharic: 'ይህ የቅርብ ጊዜ ንባብ ታሪክዎን ብቻ ያጠፋል።',
            english: 'This removes only your recent-reading history.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_ui(amharic: 'ይቅር', english: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_ui(amharic: 'አጥፋ', english: 'Clear')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ui(
              amharic: 'የቅርብ ንባብ ታሪክ ጠፍቷል።',
              english: 'Recent reading was cleared.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = '${(_preferences.textScale * 100).round()}%';

    return Scaffold(
      appBar: AppBar(
        title: Text(_ui(amharic: 'ቅንብር', english: 'Settings')),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SettingsHero(appLanguage: _appLanguage),
                  const SizedBox(height: 20),
                  _SettingsSection(
                    title: _ui(amharic: 'መተግበሪያ', english: 'Application'),
                    icon: Icons.language_rounded,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ui(
                                amharic: 'የመተግበሪያ ቋንቋ',
                                english: 'App language',
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ui(
                                amharic: 'የምናሌዎችንና የመቆጣጠሪያዎችን ቋንቋ ይቀይሩ።',
                                english:
                                    'Change the language of menus and controls.',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<AppLanguage>(
                                segments: const [
                                  ButtonSegment(
                                    value: AppLanguage.amharic,
                                    icon: Icon(Icons.translate_rounded),
                                    label: Text('አማርኛ'),
                                  ),
                                  ButtonSegment(
                                    value: AppLanguage.english,
                                    icon: Icon(Icons.language_rounded),
                                    label: Text('English'),
                                  ),
                                ],
                                selected: {_appLanguage},
                                onSelectionChanged: _setAppLanguage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: _ui(amharic: 'የንባብ ቅንብር', english: 'Reader'),
                    icon: Icons.auto_stories_rounded,
                    children: [
                      ListTile(
                        leading: const _SettingIcon(
                          icon: Icons.menu_book_rounded,
                        ),
                        title: Text(
                          _ui(amharic: 'የጽሑፍ ቋንቋ', english: 'Content language'),
                        ),
                        subtitle: Text(
                          _ui(
                            amharic: 'በአንባቢው ውስጥ የሚታየውን ጽሑፍ ይምረጡ።',
                            english: 'Choose the text displayed in the reader.',
                          ),
                        ),
                        trailing: DropdownButton<ReaderLanguage>(
                          value: _preferences.language,
                          underline: const SizedBox.shrink(),
                          onChanged: _setReaderLanguage,
                          items: ReaderLanguage.values.map((language) {
                            return DropdownMenuItem(
                              value: language,
                              child: Text(_readerLanguageLabel(language)),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(indent: 72),
                      ListTile(
                        leading: const _SettingIcon(
                          icon: Icons.format_size_rounded,
                        ),
                        title: Text(
                          _ui(amharic: 'የፊደል መጠን', english: 'Text size'),
                        ),
                        subtitle: Slider(
                          value: _textScales
                              .indexOf(_preferences.textScale)
                              .toDouble(),
                          min: 0,
                          max: (_textScales.length - 1).toDouble(),
                          divisions: _textScales.length - 1,
                          label: percent,
                          onChanged: _setTextScale,
                        ),
                        trailing: Text(
                          percent,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Divider(indent: 72),
                      SwitchListTile(
                        secondary: const _SettingIcon(
                          icon: Icons.auto_awesome_rounded,
                          color: AppTheme.sacredRed,
                        ),
                        title: Text(
                          _ui(
                            amharic: 'ቅዱሳት ስሞችን በቀይ',
                            english: 'Sacred names in red',
                          ),
                        ),
                        subtitle: Text(
                          _ui(
                            amharic: 'የእግዚአብሔርንና የቅዱሳንን ስም ያጉሉ።',
                            english:
                                'Highlight divine and saint names while reading.',
                          ),
                        ),
                        value: _preferences.highlightSacredNames,
                        onChanged: _setSacredNames,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: _ui(amharic: 'ከመስመር ውጭ', english: 'Offline'),
                    icon: Icons.offline_pin_rounded,
                    children: [
                      ListTile(
                        leading: const _SettingIcon(
                          icon: Icons.download_done_rounded,
                          color: AppTheme.controlGreen,
                        ),
                        title: Text(
                          _ui(
                            amharic: 'ቅዳሴ ማርያም ዝግጁ ነው',
                            english: 'Anaphora of St. Mary is ready',
                          ),
                        ),
                        subtitle: Text(
                          _ui(
                            amharic: 'የተቀመጠውን ሙሉ ጽሑፍ ያለ ኢንተርኔት ማንበብ ይችላሉ።',
                            english:
                                'Saved content remains readable without internet.',
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.controlGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: _ui(amharic: 'ማጋራትና ውሂብ', english: 'Share & data'),
                    icon: Icons.hub_outlined,
                    children: [
                      ListTile(
                        leading: const _SettingIcon(
                          icon: Icons.android_rounded,
                          color: AppTheme.controlGreen,
                        ),
                        title: Text(
                          _ui(
                            amharic: 'መተግበሪያውን እንደ APK ያጋሩ',
                            english: 'Share the app as an APK',
                          ),
                        ),
                        subtitle: Text(
                          _ui(
                            amharic:
                                'የተጫነውን APK በBluetooth፣ Telegram ወይም በሌላ መተግበሪያ ይላኩ።',
                            english:
                                'Send the installed APK through Bluetooth, Telegram, or another app.',
                          ),
                        ),
                        trailing: _sharingApk
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded),
                        onTap: _sharingApk ? null : _shareApk,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(72, 0, 16, 14),
                        child: Text(
                          _ui(
                            amharic:
                                'ተቀባዩ APKውን ለመጫን “ከዚህ ምንጭ ፍቀድ” ማብራት ሊኖርበት ይችላል።',
                            english:
                                'The receiver may need to allow installation from that sharing app.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.sacredRed),
                        ),
                      ),
                      const Divider(indent: 72),
                      ListTile(
                        leading: const _SettingIcon(
                          icon: Icons.delete_outline_rounded,
                        ),
                        title: Text(
                          _ui(
                            amharic: 'የቅርብ ንባብ ያጥፉ',
                            english: 'Clear recent reading',
                          ),
                        ),
                        subtitle: Text(
                          _ui(
                            amharic: 'የንባብ ታሪክዎን ከዚህ መሣሪያ ያስወግዱ።',
                            english:
                                'Remove your reading history from this device.',
                          ),
                        ),
                        onTap: _clearHistory,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _readerLanguageLabel(ReaderLanguage language) {
    return switch (language) {
      ReaderLanguage.all => _ui(amharic: 'ሁሉም', english: 'All'),
      ReaderLanguage.geez => 'ግዕዝ',
      ReaderLanguage.amharic => 'አማርኛ',
      ReaderLanguage.english => 'English',
    };
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.appLanguage});

  final AppLanguage appLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.controlGreen, Color(0xFF204231)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppTheme.parchmentSurface,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLanguage.text(
                    amharic: 'የእርስዎ የንባብ ልምድ',
                    english: 'Your reading experience',
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.parchmentSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appLanguage.text(
                    amharic: 'ቋንቋን፣ ጽሑፍንና ከመስመር ውጭ አጠቃቀምን ያስተካክሉ።',
                    english: 'Personalize language, text, and offline access.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.parchmentSurface.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.parchmentSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.warmOutline.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 19, color: AppTheme.liturgicalGold),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.controlGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (color ?? AppTheme.liturgicalGold).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 21, color: color ?? AppTheme.liturgicalGold),
    );
  }
}
