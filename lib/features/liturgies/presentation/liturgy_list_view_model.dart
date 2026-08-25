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
  bool _isSynchronizing = false;
  bool _isDisposed = false;

  LiturgyListStatus get status => _status;
  List<Liturgy> get liturgies => _liturgies;
  String? get errorMessage => _errorMessage;

  static const _catalogOrder = <String, int>{
    'liturgy-guide': 0,
    'apostles': 1,
    'our-lord-jesus-christ': 2,
    'st-mary': 3,
    'st-athanasius': 4,
    'st-basil': 5,
    'st-gregory': 6,
    'three-hundred': 7,
    'st-epiphanius': 8,
    'st-john-chrysostom': 9,
    'st-cyril': 10,
    'st-jacob-of-serough': 11,
    'st-dioscorus': 12,
    'st-dioscorus-fasika-pentecost': 13,
  };

  List<Liturgy> _sortLiturgies(List<Liturgy> liturgies) {
    final sorted = List<Liturgy>.of(liturgies);
    sorted.sort((left, right) {
      final leftOrder = _catalogOrder[left.slug] ?? _catalogOrder.length;
      final rightOrder = _catalogOrder[right.slug] ?? _catalogOrder.length;
      final orderComparison = leftOrder.compareTo(rightOrder);

      return orderComparison != 0
          ? orderComparison
          : left.name.compareTo(right.name);
    });
    return sorted;
  }

  Future<void> loadLiturgies() async {
    if (_status == LiturgyListStatus.loading) return;

    _status = LiturgyListStatus.loading;
    _errorMessage = null;
    _notifyListeners();

    try {
      final liturgies = await _repository.getLiturgies();
      _liturgies = List.unmodifiable(_sortLiturgies(liturgies));
      _status = LiturgyListStatus.success;
    } catch (error) {
      _errorMessage = error.toString();
      _status = LiturgyListStatus.failure;
    }

    _notifyListeners();
  }

  Future<void> synchronizeContent() async {
    if (_isSynchronizing) return;
    _isSynchronizing = true;

    try {
      final liturgies = await _repository.synchronizeContent();
      if (liturgies.isNotEmpty) {
        _liturgies = List.unmodifiable(_sortLiturgies(liturgies));
        _status = LiturgyListStatus.success;
        _errorMessage = null;
        _notifyListeners();
      }
    } catch (_) {
      // Synchronization is best-effort; keep the current offline catalog.
    } finally {
      _isSynchronizing = false;
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
