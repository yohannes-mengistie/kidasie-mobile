import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/announcement.dart';

final class AnnouncementApiService {
  const AnnouncementApiService({
    required Uri baseUrl,
    required http.Client client,
  }) : _baseUrl = baseUrl,
       _client = client;

  final Uri _baseUrl;
  final http.Client _client;

  Future<List<Announcement>> fetchAnnouncements() async {
    final uri = _baseUrl.resolve('api/v1/announcements');
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AnnouncementApiException(response.statusCode);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw const FormatException('Invalid announcement response');
    }

    return List.unmodifiable(
      data.whereType<Map<String, dynamic>>().map(Announcement.fromJson),
    );
  }
}

final class AnnouncementApiException implements Exception {
  const AnnouncementApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Failed to fetch announcements (HTTP $statusCode)';
}
