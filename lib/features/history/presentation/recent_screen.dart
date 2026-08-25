import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/history/reading_history.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../liturgies/data/liturgy_repository.dart';
import '../../liturgies/domain/liturgy.dart';
import '../../liturgies/presentation/liturgy_reader_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({
    required this.repository,
    required this.preferencesStore,
    required this.historyStore,
    required this.appLanguage,
    required this.onHistoryChanged,
    super.key,
  });

  final LiturgyRepository repository;
  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final AppLanguage appLanguage;
  final VoidCallback onHistoryChanged;

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  late Future<List<ReadingHistoryEntry>> _history;

  String _ui({required String amharic, required String english}) {
    return widget.appLanguage.text(amharic: amharic, english: english);
  }

  @override
  void initState() {
    super.initState();
    _history = widget.historyStore.load();
  }

  Future<void> _open(Liturgy liturgy) async {
    await widget.historyStore.record(liturgy);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LiturgyReaderScreen(
          repository: widget.repository,
          liturgy: liturgy,
          preferencesStore: widget.preferencesStore,
          appLanguage: widget.appLanguage,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _history = widget.historyStore.load();
      });
      widget.onHistoryChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ui(amharic: 'የቅርብ ንባብ', english: 'Recent reading')),
      ),
      body: SafeArea(
        child: ParchmentBackdrop(
          child: FutureBuilder<List<ReadingHistoryEntry>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return _EmptyHistory(appLanguage: widget.appLanguage);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final liturgy = entry.liturgy;
                  final amharicName = liturgy.nameAm.isEmpty
                      ? liturgy.name
                      : liturgy.nameAm;
                  final primaryName = widget.appLanguage.isEnglish
                      ? liturgy.name
                      : amharicName;
                  final secondaryName = widget.appLanguage.isEnglish
                      ? amharicName
                      : liturgy.name;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassSurface(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        leading: Container(
                          width: 44,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.controlGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            liturgy.hasAudio
                                ? Icons.headphones_rounded
                                : Icons.menu_book_rounded,
                            color: AppTheme.controlGreen,
                          ),
                        ),
                        title: Text(
                          primaryName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          (secondaryName == primaryName
                                  ? ''
                                  : '$secondaryName\n') +
                              _relativeDate(entry.openedAt),
                        ),
                        isThreeLine: secondaryName != primaryName,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _open(liturgy),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final openedDay = DateTime(localDate.year, localDate.month, localDate.day);
    final days = today.difference(openedDay).inDays;

    if (widget.appLanguage.isEnglish) {
      return switch (days) {
        0 => 'Today',
        1 => 'Yesterday',
        _ when days > 1 => '$days days ago',
        _ => 'Recently',
      };
    }

    return switch (days) {
      0 => 'ዛሬ',
      1 => 'ትናንት',
      _ when days > 1 => 'ከ$days ቀናት በፊት',
      _ => 'በቅርቡ',
    };
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.appLanguage});

  final AppLanguage appLanguage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 52),
            const SizedBox(height: 16),
            Text(
              appLanguage.text(
                amharic: 'ገና የተነበበ ቅዳሴ የለም',
                english: 'Nothing read yet',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              appLanguage.text(
                amharic: 'በቅርቡ የከፈቷቸው ቅዳሴዎች እዚህ ይታያሉ።',
                english: 'Your recently opened liturgies will appear here.',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
