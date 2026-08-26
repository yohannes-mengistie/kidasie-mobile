import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/announcement.dart';

final class AnnouncementLocalDataSource {
  static const String _cacheDirectory = 'announcement_cache';
  static const String _cacheFileName = 'announcements.json';

  Future<List<Announcement>> readAnnouncements() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) {
        return const [];
      }

      final decoded = jsonDecode(await file.readAsString());
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List) {
        return const [];
      }

      return List.unmodifiable(
        data.whereType<Map<String, dynamic>>().map(Announcement.fromJson),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAnnouncements(List<Announcement> announcements) async {
    final file = await _cacheFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'data': announcements.map((item) => item.toJson()).toList()}),
      flush: true,
    );
  }

  Future<File> _cacheFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_cacheDirectory/$_cacheFileName');
  }
}
