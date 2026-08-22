import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/liturgies/domain/liturgy.dart';

final class ReadingHistoryEntry {
  const ReadingHistoryEntry({required this.liturgy, required this.openedAt});

  final Liturgy liturgy;
  final DateTime openedAt;

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) {
    final liturgyJson = json['liturgy'];
    if (liturgyJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid reading history entry');
    }

    return ReadingHistoryEntry(
      liturgy: Liturgy.fromJson(liturgyJson),
      openedAt:
          DateTime.tryParse(json['opened_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'liturgy': liturgy.toJson(),
    'opened_at': openedAt.toIso8601String(),
  };
}

final class ReadingHistoryStore {
  ReadingHistoryStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _historyKey = 'reading.history';
  static const int _maximumEntries = 20;

  final SharedPreferencesAsync _preferences;

  Future<List<ReadingHistoryEntry>> load() async {
    final encoded = await _preferences.getString(_historyKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return const [];
      }

      return List.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(
          ReadingHistoryEntry.fromJson,
        ),
      );
    } on FormatException {
      return const [];
    }
  }

  Future<void> record(Liturgy liturgy) async {
    final entries = (await load()).toList()
      ..removeWhere((entry) => entry.liturgy.slug == liturgy.slug)
      ..insert(
        0,
        ReadingHistoryEntry(liturgy: liturgy, openedAt: DateTime.now()),
      );

    final limited = entries.take(_maximumEntries);
    await _preferences.setString(
      _historyKey,
      jsonEncode(limited.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> clear() {
    return _preferences.remove(_historyKey);
  }
}
