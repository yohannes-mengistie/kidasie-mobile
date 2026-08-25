import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/liturgies/domain/liturgy.dart';

final class LiturgyAudioController extends ChangeNotifier {
  LiturgyAudioController({
    required this.slug,
    required this.audio,
    AudioPlayer? player,
    http.Client? client,
  }) : _player = player ?? AudioPlayer(),
       _client = client ?? http.Client() {
    _subscriptions.addAll([
      _player.positionStream.listen((value) {
        _position = value;
        _notify();
      }),
      _player.durationStream.listen((value) {
        _playerDuration = value;
        _notify();
      }),
      _player.playerStateStream.listen((value) {
        _playing = value.playing;
        _processingState = value.processingState;
        if (value.processingState == ProcessingState.completed) {
          _position = duration;
        }
        _notify();
      }),
      _player.speedStream.listen((value) {
        _speed = value;
        _notify();
      }),
      _player.errorStream.listen((error) {
        _errorMessage = error.message;
        _notify();
      }),
    ]);

    unawaited(_discoverDownload());
  }

  final String slug;
  final LiturgyAudio audio;
  final AudioPlayer _player;
  final http.Client _client;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Duration _position = Duration.zero;
  Duration? _playerDuration;
  ProcessingState _processingState = ProcessingState.idle;
  bool _playing = false;
  bool _sourceLoaded = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  bool _disposed = false;
  double _speed = 1;
  double _downloadProgress = 0;
  String? _errorMessage;
  File? _downloadedFile;

  Duration get position => _position;
  Duration get duration =>
      _playerDuration ?? Duration(milliseconds: audio.durationMs);
  bool get playing => _playing;
  bool get isDownloaded => _isDownloaded;
  bool get isDownloading => _isDownloading;
  double get speed => _speed;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isBuffering =>
      _processingState == ProcessingState.loading ||
      _processingState == ProcessingState.buffering;

  String get identity => '${audio.url}|${audio.sha256}';

  Future<void> togglePlayback() async {
    try {
      _errorMessage = null;
      await _ensureSource();

      if (_processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }

      if (_player.playing) {
        await _player.pause();
      } else {
        unawaited(_player.play());
      }
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> seek(Duration value) async {
    try {
      await _ensureSource();
      final bounded = value > duration ? duration : value;
      await _player.seek(bounded);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> setSpeed(double value) async {
    try {
      await _player.setSpeed(value);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> download() async {
    if (_isDownloading || _isDownloaded) {
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0;
    _errorMessage = null;
    _notify();

    File? partialFile;
    IOSink? sink;

    try {
      final target = await _targetFile();
      partialFile = File('${target.path}.part');
      await partialFile.parent.create(recursive: true);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }

      final request = http.Request('GET', Uri.parse(audio.url));
      final response = await _client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Audio download failed with status ${response.statusCode}',
          uri: Uri.parse(audio.url),
        );
      }

      final expectedBytes = response.contentLength ?? audio.sizeBytes;
      var receivedBytes = 0;
      sink = partialFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (expectedBytes > 0) {
          _downloadProgress = (receivedBytes / expectedBytes).clamp(0, 1);
          _notify();
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      final actualSize = await partialFile.length();
      if (actualSize != audio.sizeBytes) {
        throw const FormatException('Downloaded audio size does not match');
      }

      final digest = await sha256.bind(partialFile.openRead()).first;
      if (digest.toString() != audio.sha256) {
        throw const FormatException('Downloaded audio checksum does not match');
      }

      if (await target.exists()) {
        await target.delete();
      }
      final savedFile = await partialFile.rename(target.path);
      partialFile = null;
      await _deleteOlderDownloads(except: savedFile);

      _downloadedFile = savedFile;
      _isDownloaded = true;
      _downloadProgress = 1;
    } catch (error) {
      _setError(error);
      if (partialFile != null && await partialFile.exists()) {
        await partialFile.delete();
      }
    } finally {
      await sink?.close();
      _isDownloading = false;
      _notify();
    }
  }

  Future<void> removeDownload() async {
    try {
      if (_sourceLoaded && _downloadedFile != null) {
        await _player.pause();
        await _player.stop();
        _sourceLoaded = false;
      }

      final file = _downloadedFile ?? await _targetFile();
      if (await file.exists()) {
        await file.delete();
      }

      _downloadedFile = null;
      _isDownloaded = false;
      _downloadProgress = 0;
      _errorMessage = null;
      _notify();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _ensureSource() async {
    if (_sourceLoaded) {
      return;
    }

    final local = await _findValidDownload();
    if (local != null) {
      await _player.setFilePath(local.path);
    } else {
      await _player.setUrl(audio.url);
    }
    _sourceLoaded = true;
  }

  Future<void> _discoverDownload() async {
    final file = await _findValidDownload();
    if (_disposed) {
      return;
    }
    _downloadedFile = file;
    _isDownloaded = file != null;
    _downloadProgress = file == null ? 0 : 1;
    _notify();
  }

  Future<File?> _findValidDownload() async {
    final file = await _targetFile();
    if (!await file.exists()) {
      return null;
    }
    if (await file.length() != audio.sizeBytes) {
      await file.delete();
      return null;
    }
    return file;
  }

  Future<File> _targetFile() async {
    final support = await getApplicationSupportDirectory();
    final safeSlug = slug.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
    final fingerprint = audio.sha256.substring(0, 16);
    return File(
      '${support.path}/liturgy_audio/$safeSlug-$fingerprint${_extension()}',
    );
  }

  String _extension() {
    if (audio.mimeType == 'audio/mp4' || audio.mimeType == 'audio/x-m4a') {
      return '.m4a';
    }
    if (audio.mimeType == 'audio/ogg') {
      return '.ogg';
    }
    return '.mp3';
  }

  Future<void> _deleteOlderDownloads({required File except}) async {
    final directory = except.parent;
    final safeSlug = slug.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
    if (!await directory.exists()) {
      return;
    }

    await for (final entity in directory.list()) {
      if (entity is! File ||
          entity.path == except.path ||
          !entity.uri.pathSegments.last.startsWith('$safeSlug-')) {
        continue;
      }
      await entity.delete();
    }
  }

  void _setError(Object error) {
    _errorMessage = error.toString();
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _client.close();
    unawaited(_player.dispose());
    super.dispose();
  }
}
