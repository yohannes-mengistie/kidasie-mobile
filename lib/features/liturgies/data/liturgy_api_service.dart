import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../domain/liturgy.dart';
import '../domain/liturgy_content.dart';

final class LiturgyApiService {
  const LiturgyApiService({required Uri baseUrl, required http.Client client})
    : _client = client,
      _baseUrl = baseUrl;

  final http.Client _client;
  final Uri _baseUrl;

  Future<List<Liturgy>> fetchLiturgies() async {
    final uri = _baseUrl.resolve('api/v1/liturgies');
    final decoded = await _getJson(uri);
    final data = decoded['data'];

    if (data is! List) {
      throw const LiturgyApiException(
        message: 'The response does not contain a liturgy list',
      );
    }
    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const LiturgyApiException(message: 'Invalid liturgy data');
          }
          return Liturgy.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<LiturgyContent> fetchLiturgyContent(String slug) async {
    final encodedSlug = Uri.encodeComponent(slug);

    final uri = _baseUrl.resolve('/api/v1/liturgies/$encodedSlug/content');

    final decoded = await _getJson(uri);
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const LiturgyApiException(
        message: 'The response does not contain liturgy content',
      );
    }

    return LiturgyContent.fromJson(data);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: const {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw LiturgyApiException(
        message: 'Failed to fetch liturgies',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const LiturgyApiException(
        message: 'Invalid response from the server',
      );
    }

    return decoded;
  }
}

final class LiturgyApiException implements Exception {
  const LiturgyApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message (HTTP $statusCode)';
  }
}
