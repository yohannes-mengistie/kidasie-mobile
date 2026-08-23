import '../domain/liturgy.dart';
import '../domain/liturgy_content.dart';
import 'liturgy_api_service.dart';
import 'liturgy_local_data_source.dart';

final class LiturgyRepository {
  const LiturgyRepository({
    required LiturgyApiService apiService,
    required LiturgyLocalDataSource localDataSource,
  }) : _apiService = apiService,
       _localDataSource = localDataSource;

  final LiturgyApiService _apiService;
  final LiturgyLocalDataSource _localDataSource;

  Future<List<Liturgy>> getLiturgies({bool refresh = false}) async {
    if (!refresh) {
      final local = await _localDataSource.readLiturgies();
      if (local.isNotEmpty) {
        return local;
      }
    }

    try {
      final remote = await _apiService.fetchLiturgies();
      await _localDataSource.writeLiturgies(remote);

      final merged = await _localDataSource.readLiturgies();
      return merged.isEmpty ? remote : merged;
    } catch (_) {
      final local = await _localDataSource.readLiturgies();
      if (local.isNotEmpty) {
        return local;
      }
      rethrow;
    }
  }

  Future<LiturgyContent> getLiturgyContent(
    String slug, {
    bool refresh = false,
  }) async {
    if (!refresh) {
      final local = await _localDataSource.readContent(slug);
      if (local != null) {
        return local;
      }
    }

    try {
      final remote = await _apiService.fetchLiturgyContent(slug);
      await _localDataSource.writeContent(remote);
      return remote;
    } catch (_) {
      final local = await _localDataSource.readContent(slug);
      if (local != null) {
        return local;
      }
      rethrow;
    }
  }
}
