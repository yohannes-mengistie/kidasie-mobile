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

  static const _catalogOrder = <String, int>{
    'liturgy-guide': 0,
    'apostles': 1,
    'our-lord-jesus-christ': 2,
    'st-mary': 3,
    'st-athanasius': 4,
    'st-gregory': 5,
    'st-epiphanius': 6,
    'st-john-chrysostom': 7,
    'st-dioscorus': 8,
    'st-dioscorus-fasika-pentecost': 9,
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

  Future<void> loadLiturgies({bool refresh = false}) async {
    if (LiturgyListStatus.loading == _status) return;
    _status = LiturgyListStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final liturgies = await _repository.getLiturgies(refresh: refresh);
      _liturgies = List.unmodifiable(_sortLiturgies(liturgies));
      _status = LiturgyListStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = LiturgyListStatus.failure;
    }

    notifyListeners();
  }
}
