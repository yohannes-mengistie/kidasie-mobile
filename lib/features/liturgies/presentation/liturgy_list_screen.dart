import 'dart:async';
import 'dart:ui';

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
      backgroundColor: const Color(0xFF082E52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF082E52),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF082E52), Color(0xFF0D5681), Color(0xFF0A3D66)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, child) => _buildBody(),
          ),
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
          color: Colors.white,
          backgroundColor: const Color(0xFF0A4C78),
          onRefresh: _viewModel.synchronizeContent,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _viewModel.liturgies.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _buildHero(),
                );
              }

              final liturgy = _viewModel.liturgies[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLiturgyCard(liturgy, index),
              );
            },
          ),
        );
    }
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.controlGreen.withValues(alpha: 0.94),
                const Color(0xFF254A38).withValues(alpha: 0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.controlGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.parchmentSurface,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ui(
                        amharic: 'የቅዳሴ መጻሕፍት',
                        english: 'Divine Liturgy Library',
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.parchmentSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ui(
                        amharic: 'በግዕዝና በአማርኛ ያንብቡ፤ ሙሉ ድምፁንም ያዳምጡ።',
                        english:
                            'Read in Ge\'ez and Amharic, and listen to complete recordings.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.parchmentSurface.withValues(
                          alpha: 0.84,
                        ),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiturgyCard(Liturgy liturgy, int position) {
    final amharicName = liturgy.nameAm.isEmpty ? liturgy.name : liturgy.nameAm;
    final primaryName = widget.appLanguage.isEnglish
        ? liturgy.name
        : amharicName;
    final secondaryName = widget.appLanguage.isEnglish
        ? amharicName
        : liturgy.name;
    final accent = liturgy.hasAudio
        ? AppTheme.sacredRed
        : liturgy.hasContent
        ? AppTheme.controlGreen
        : AppTheme.liturgicalGold;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color(0xFFF8FBFF).withValues(alpha: 0.9),
          child: InkWell(
            onTap: () => _openLiturgy(liturgy),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF031D35).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 58,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: accent.withValues(alpha: 0.24)),
                    ),
                    child: Icon(
                      liturgy.hasAudio
                          ? Icons.headphones_rounded
                          : Icons.menu_book_rounded,
                      color: accent,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                        ),
                        if (secondaryName != primaryName) ...[
                          const SizedBox(height: 3),
                          Text(
                            secondaryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            if (liturgy.hasContent)
                              _AvailabilityPill(
                                icon: Icons.article_outlined,
                                label: _ui(amharic: 'ጽሑፍ', english: 'Text'),
                                color: AppTheme.controlGreen,
                              ),
                            if (liturgy.hasAudio)
                              _AvailabilityPill(
                                icon: Icons.graphic_eq_rounded,
                                label: _ui(amharic: 'ድምፅ', english: 'Audio'),
                                color: AppTheme.sacredRed,
                              ),
                            if (!liturgy.hasContent && !liturgy.hasAudio)
                              _AvailabilityPill(
                                icon: Icons.schedule_rounded,
                                label: _ui(
                                  amharic: 'በቅርብ ጊዜ',
                                  english: 'Coming soon',
                                ),
                                color: AppTheme.liturgicalGold,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
