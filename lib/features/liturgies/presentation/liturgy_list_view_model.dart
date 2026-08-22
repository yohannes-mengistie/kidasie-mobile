import 'package:flutter/foundation.dart';
import '../data/liturgy_repository.dart';
import '../domain/liturgy.dart';

enum LiturgyListStatus { initial, loading, success, failure }

final class LiturgyListViewModel extends ChangeNotifier {
  LiturgyListViewModel({required LiturgyRepository repository})
    : _repository = repository;

  final LiturgyRepository _repository;
  LiturgyListStatus _status = LiturgyListStatus.initial;
  List<Liturgy> _liturgies = [];
  String? _errorMessage;

  LiturgyListStatus get status => _status;
  List<Liturgy> get liturgies => _liturgies;
  String? get errorMessage => _errorMessage;

  Future<void> loadLiturgies({bool refresh = false}) async {
    if (LiturgyListStatus.loading == _status) return;
    _status = LiturgyListStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final liturgies = await _repository.getLiturgies(refresh: refresh);
      _liturgies = List.unmodifiable(liturgies);
      _status = LiturgyListStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = LiturgyListStatus.failure;
    }

    notifyListeners();
  }
}
