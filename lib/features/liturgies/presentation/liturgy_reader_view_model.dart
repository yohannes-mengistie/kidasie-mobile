import 'package:flutter/foundation.dart';
import '../data/liturgy_repository.dart';
import '../domain/liturgy_content.dart';

enum LiturgyReaderStatus { initial, loading, success, failure }

final class LiturgyReaderViewModel extends ChangeNotifier {
  LiturgyReaderViewModel({
    required LiturgyRepository repository,
    required String slug,
  }) : _repository = repository,
       _slug = slug;

  final LiturgyRepository _repository;
  final String _slug;

  LiturgyReaderStatus _status = LiturgyReaderStatus.initial;
  LiturgyContent? _content;
  String? _errorMessage;

  LiturgyReaderStatus get status => _status;
  LiturgyContent? get content => _content;
  String? get errorMessage => _errorMessage;

  Future<void> loadContent({bool refresh = false}) async {
    if (_status == LiturgyReaderStatus.loading) {
      return;
    }

    _status = LiturgyReaderStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _content = await _repository.getLiturgyContent(_slug, refresh: refresh);
      _status = LiturgyReaderStatus.success;
    } catch (_) {
      _errorMessage = 'Unable to load this liturgy. Please try again.';
      _status = LiturgyReaderStatus.failure;
    }

    notifyListeners();
  }
}
