import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:orthodox_liturgy/core/config/app_config.dart';
import 'package:orthodox_liturgy/core/history/reading_history.dart';
import 'package:orthodox_liturgy/core/localization/app_language.dart';
import 'package:orthodox_liturgy/core/preferences/reader_preferences.dart';
import 'package:orthodox_liturgy/features/announcements/data/announcement_api_service.dart';
import 'package:orthodox_liturgy/features/announcements/data/announcement_local_data_source.dart';
import 'package:orthodox_liturgy/features/announcements/data/announcement_read_store.dart';
import 'package:orthodox_liturgy/features/announcements/data/announcement_repository.dart';
import 'package:orthodox_liturgy/features/liturgies/data/liturgy_api_service.dart';
import 'package:orthodox_liturgy/features/liturgies/data/liturgy_local_data_source.dart';
import 'package:orthodox_liturgy/features/liturgies/data/liturgy_repository.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

class KidasieApp extends StatefulWidget {
  const KidasieApp({super.key});

  @override
  State<KidasieApp> createState() => _KidasieAppState();
}

class _KidasieAppState extends State<KidasieApp> {
  late final http.Client _httpClient;
  late final LiturgyRepository _liturgyRepository;
  late final ReaderPreferencesStore _readerPreferencesStore;
  late final ReadingHistoryStore _historyStore;
  late final AnnouncementRepository _announcementRepository;
  late final AnnouncementReadStore _announcementReadStore;

  AppLanguage _appLanguage = AppLanguage.amharic;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    final apiService = LiturgyApiService(
      client: _httpClient,
      baseUrl: AppConfig.apiBaseUri,
    );
    _liturgyRepository = LiturgyRepository(
      apiService: apiService,
      localDataSource: LiturgyLocalDataSource(),
    );
    _readerPreferencesStore = ReaderPreferencesStore();
    _historyStore = ReadingHistoryStore();
    _announcementRepository = AnnouncementRepository(
      apiService: AnnouncementApiService(
        client: _httpClient,
        baseUrl: AppConfig.apiBaseUri,
      ),
      localDataSource: AnnouncementLocalDataSource(),
    );
    _announcementReadStore = AnnouncementReadStore();
    unawaited(_loadAppLanguage());
  }

  Future<void> _loadAppLanguage() async {
    final preferences = await _readerPreferencesStore.load();
    if (!mounted || preferences.appLanguage == _appLanguage) {
      return;
    }

    setState(() {
      _appLanguage = preferences.appLanguage;
    });
  }

  void _setAppLanguage(AppLanguage language) {
    if (_appLanguage == language) {
      return;
    }

    setState(() {
      _appLanguage = language;
    });
    unawaited(_readerPreferencesStore.saveAppLanguage(language));
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appLanguage.text(
        amharic: 'ሥርዐተ ቅዳሴ',
        english: 'Orthodox Liturgy',
      ),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _appLanguage.locale,
      supportedLocales: const [Locale('am'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AppShell(
        repository: _liturgyRepository,
        preferencesStore: _readerPreferencesStore,
        historyStore: _historyStore,
        announcementRepository: _announcementRepository,
        announcementReadStore: _announcementReadStore,
        appLanguage: _appLanguage,
        onAppLanguageChanged: _setAppLanguage,
      ),
    );
  }
}
