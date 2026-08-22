import 'package:flutter/material.dart';

import '../../../core/history/reading_history.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../liturgies/data/liturgy_repository.dart';
import '../../liturgies/domain/liturgy.dart';
import '../../liturgies/presentation/liturgy_reader_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({
    required this.repository,
    required this.preferencesStore,
    required this.historyStore,
    required this.onHistoryChanged,
    super.key,
  });

  final LiturgyRepository repository;
  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final VoidCallback onHistoryChanged;

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  late Future<List<ReadingHistoryEntry>> _history;

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('የቅርብ ንባብ'),
            Text(
              'Recent reading',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<ReadingHistoryEntry>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return const _EmptyHistory();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final liturgy = entry.liturgy;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(
                    liturgy.nameAm.isEmpty ? liturgy.name : liturgy.nameAm,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${liturgy.name}\n${_relativeDate(entry.openedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(liturgy),
                );
              },
            );
          },
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

    return switch (days) {
      0 => 'ዛሬ',
      1 => 'ትናንት',
      _ when days > 1 => 'ከ$days ቀናት በፊት',
      _ => 'በቅርቡ',
    };
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 52),
            SizedBox(height: 16),
            Text('ገና የተነበበ ቅዳሴ የለም'),
            SizedBox(height: 6),
            Text('Your recently opened liturgies will appear here.'),
          ],
        ),
      ),
    );
  }
}
