import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orthodox_liturgy/core/config/app_config.dart';
import 'package:orthodox_liturgy/core/history/reading_history.dart';
import 'package:orthodox_liturgy/core/preferences/reader_preferences.dart';
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
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ሥርዐተ ቅዳሴ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        repository: _liturgyRepository,
        preferencesStore: _readerPreferencesStore,
        historyStore: _historyStore,
      ),
    );
  }
}
