import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/announcement.dart';

final class AnnouncementReadStore {
  AnnouncementReadStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _readVersionsKey = 'announcements.readVersions';

  final SharedPreferencesAsync _preferences;

  Future<Map<String, int>> loadReadVersions() async {
    final encoded = await _preferences.getString(_readVersionsKey);
    if (encoded == null || encoded.isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key: entry.value as int,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> markRead(Announcement announcement) async {
    final versions = Map<String, int>.from(await loadReadVersions());
    final current = versions[announcement.slug] ?? 0;
    if (current >= announcement.version) {
      return;
    }
    versions[announcement.slug] = announcement.version;
    await _preferences.setString(_readVersionsKey, jsonEncode(versions));
  }

  bool isUnread(Announcement announcement, Map<String, int> readVersions) {
    return (readVersions[announcement.slug] ?? 0) < announcement.version;
  }

  int countUnread(
    List<Announcement> announcements,
    Map<String, int> readVersions,
  ) {
    return announcements
        .where((announcement) => isUnread(announcement, readVersions))
        .length;
  }
}
