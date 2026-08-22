import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/liturgy.dart';
import '../domain/liturgy_content.dart';

final class LiturgyLocalDataSource {
  static const String _assetDirectory = 'assets/offline';
  static const String _cacheDirectory = 'liturgy_cache';

  Future<List<Liturgy>> readLiturgies() async {
    final cached = await _readCacheFile('liturgies.json');
    final fromCache = _decodeLiturgies(cached);
    if (fromCache.isNotEmpty) {
      return fromCache;
    }

    final bundled = await _readAsset('$_assetDirectory/liturgies.json');
    return _decodeLiturgies(bundled);
  }

  Future<void> writeLiturgies(List<Liturgy> liturgies) {
    return _writeCacheFile(
      'liturgies.json',
      jsonEncode({'data': liturgies.map((item) => item.toJson()).toList()}),
    );
  }

  Future<LiturgyContent?> readContent(String slug) async {
    final safeSlug = _safeSlug(slug);
    final cached = await _readCacheFile('$safeSlug.json');
    final fromCache = _decodeContent(cached);
    final bundled = await _readAsset('$_assetDirectory/$safeSlug.json');
    final fromBundle = _decodeContent(bundled);

    if (fromCache == null) {
      return fromBundle;
    }
    if (fromBundle == null) {
      return fromCache;
    }

    return fromBundle.liturgy.contentVersion > fromCache.liturgy.contentVersion
        ? fromBundle
        : fromCache;
  }

  Future<void> writeContent(LiturgyContent content) {
    return _writeCacheFile(
      '${_safeSlug(content.liturgy.slug)}.json',
      jsonEncode({'data': content.toJson()}),
    );
  }

  Future<String?> _readCacheFile(String filename) async {
    try {
      final file = await _cacheFile(filename);
      if (!await file.exists()) {
        return null;
      }
      return file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  Future<String?> _readAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } on FlutterError {
      return null;
    }
  }

  Future<void> _writeCacheFile(String filename, String contents) async {
    final file = await _cacheFile(filename);
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);
  }

  Future<File> _cacheFile(String filename) async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File('${supportDirectory.path}/$_cacheDirectory/$filename');
  }

  List<Liturgy> _decodeLiturgies(String? encoded) {
    try {
      final decoded = jsonDecode(encoded ?? '');
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List) {
        return const [];
      }
      return List.unmodifiable(
        data.whereType<Map<String, dynamic>>().map(Liturgy.fromJson),
      );
    } on FormatException {
      return const [];
    }
  }

  LiturgyContent? _decodeContent(String? encoded) {
    try {
      final decoded = jsonDecode(encoded ?? '');
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return LiturgyContent.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  String _safeSlug(String slug) {
    return slug.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
  }
}
