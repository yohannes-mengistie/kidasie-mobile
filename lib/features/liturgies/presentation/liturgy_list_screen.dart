import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/history/reading_history.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../../core/sharing/app_share_service.dart';
import '../data/liturgy_repository.dart';
import '../domain/liturgy.dart';
import 'liturgy_list_view_model.dart';
import 'liturgy_reader_screen.dart';

class LiturgyListScreen extends StatefulWidget {
  const LiturgyListScreen({
    required this.repository,
    required this.historyStore,
    required this.onHistoryChanged,
    required this.preferencesStore,
    required this.appLanguage,
    super.key,
  });

  final LiturgyRepository repository;
  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final AppLanguage appLanguage;
  final VoidCallback onHistoryChanged;

  @override
  State<LiturgyListScreen> createState() => _LiturgyListScreenState();
}

class _LiturgyListScreenState extends State<LiturgyListScreen> {
  late final LiturgyListViewModel _viewModel;

  String _ui({required String amharic, required String english}) {
    return widget.appLanguage.text(amharic: amharic, english: english);
  }

  @override
  void initState() {
    super.initState();
    _viewModel = LiturgyListViewModel(repository: widget.repository);
    unawaited(_loadAndSynchronize());
  }

  Future<void> _loadAndSynchronize() async {
    await _viewModel.loadLiturgies();
    if (!mounted) return;

    await _viewModel.synchronizeContent();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openLiturgy(Liturgy liturgy) async {
    await widget.historyStore.record(liturgy);
    widget.onHistoryChanged();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LiturgyReaderScreen(
          repository: widget.repository,
          liturgy: liturgy,
          preferencesStore: widget.preferencesStore,
          appLanguage: widget.appLanguage,
        ),
      ),
    );

    if (mounted) {
      widget.onHistoryChanged();
    }
  }

  Future<void> _shareApp() async {
    try {
      await AppShareService.shareApp();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ui(
                amharic: 'የAPK ፋይሉን ማጋራት አልተቻለም።',
                english: 'The APK file could not be shared.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ui(amharic: 'ሥርዐተ ቅዳሴ', english: 'Divine Liturgy')),
        actions: [
          IconButton(
            tooltip: _ui(
              amharic: 'መተግበሪያውን እንደ APK ያጋሩ',
              english: 'Share app as APK',
            ),
            onPressed: () => unawaited(_shareApp()),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) => _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.status) {
      case LiturgyListStatus.initial:
      case LiturgyListStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LiturgyListStatus.failure:
        return _buildError();

      case LiturgyListStatus.success:
        if (_viewModel.liturgies.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          onRefresh: _viewModel.synchronizeContent,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _viewModel.liturgies.length + 1,
            separatorBuilder: (context, index) =>
                index == 0 ? const SizedBox(height: 18) : const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.warmOutline.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: AppTheme.liturgicalGold,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _ui(
                          amharic: 'ቅዳሴን በግዕዝ፣ በአማርኛና በእንግሊዝኛ ያንብቡ',
                          english:
                              'Read the liturgy in Ge\'ez, Amharic, and English',
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.offline_pin_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ui(
                                amharic: 'ለቅዳሴ በተመስጦ እንቁም',
                                english:
                                    'Available whenever you need it, even offline',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              final liturgy = _viewModel.liturgies[index - 1];
              final amharicName = liturgy.nameAm.isEmpty
                  ? liturgy.name
                  : liturgy.nameAm;
              final primaryName = widget.appLanguage.isEnglish
                  ? liturgy.name
                  : amharicName;
              final secondaryName = widget.appLanguage.isEnglish
                  ? amharicName
                  : liturgy.name;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                leading: const Icon(Icons.menu_book_outlined, size: 30),
                title: Text(
                  primaryName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: secondaryName == primaryName
                    ? null
                    : Text(secondaryName),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openLiturgy(liturgy),
              );
            },
          ),
        );
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.appLanguage.isEnglish
                  ? (_viewModel.errorMessage ?? 'Something went wrong.')
                  : 'ይዘቱን መጫን አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _viewModel.loadLiturgies,
              icon: const Icon(Icons.refresh),
              label: Text(_ui(amharic: 'እንደገና ሞክር', english: 'Try again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _viewModel.loadLiturgies,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          const Icon(Icons.menu_book_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            _ui(
              amharic: 'እስካሁን የተዘጋጀ ቅዳሴ የለም።',
              english: 'No liturgies are available yet.',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
