import '../domain/announcement.dart';
import 'announcement_api_service.dart';
import 'announcement_local_data_source.dart';

final class AnnouncementRepository {
  const AnnouncementRepository({
    required AnnouncementApiService apiService,
    required AnnouncementLocalDataSource localDataSource,
  }) : _apiService = apiService,
       _localDataSource = localDataSource;

  final AnnouncementApiService _apiService;
  final AnnouncementLocalDataSource _localDataSource;

  Future<List<Announcement>> getAnnouncements({bool refresh = false}) async {
    if (!refresh) {
      final cached = await _localDataSource.readAnnouncements();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final remote = await _apiService.fetchAnnouncements();
      await _localDataSource.writeAnnouncements(remote);
      return remote;
    } catch (_) {
      final cached = await _localDataSource.readAnnouncements();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }
}
