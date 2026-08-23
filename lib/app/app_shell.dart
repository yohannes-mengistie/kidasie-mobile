import 'package:flutter/material.dart';

import '../core/history/reading_history.dart';
import '../core/localization/app_language.dart';
import '../core/preferences/reader_preferences.dart';
import '../features/history/presentation/recent_screen.dart';
import '../features/liturgies/data/liturgy_repository.dart';
import '../features/liturgies/presentation/liturgy_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.repository,
    required this.preferencesStore,
    required this.historyStore,
    required this.appLanguage,
    required this.onAppLanguageChanged,
    super.key,
  });

  final LiturgyRepository repository;
  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final AppLanguage appLanguage;
  final ValueChanged<AppLanguage> onAppLanguageChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _historyRevision = 0;

  void _historyChanged() {
    setState(() {
      _historyRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LiturgyListScreen(
            repository: widget.repository,
            preferencesStore: widget.preferencesStore,
            historyStore: widget.historyStore,
            appLanguage: widget.appLanguage,
            onHistoryChanged: _historyChanged,
          ),
          RecentScreen(
            key: ValueKey(_historyRevision),
            repository: widget.repository,
            preferencesStore: widget.preferencesStore,
            historyStore: widget.historyStore,
            appLanguage: widget.appLanguage,
            onHistoryChanged: _historyChanged,
          ),
          SettingsScreen(
            preferencesStore: widget.preferencesStore,
            historyStore: widget.historyStore,
            appLanguage: widget.appLanguage,
            onAppLanguageChanged: widget.onAppLanguageChanged,
            onHistoryChanged: _historyChanged,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories_rounded),
            label: widget.appLanguage.text(amharic: 'ቅዳሴ', english: 'Liturgy'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: widget.appLanguage.text(amharic: 'የቅርብ', english: 'Recent'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: widget.appLanguage.text(
              amharic: 'ቅንብር',
              english: 'Settings',
            ),
          ),
        ],
      ),
    );
  }
}
