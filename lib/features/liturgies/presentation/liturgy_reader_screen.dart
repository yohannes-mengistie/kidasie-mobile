import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../../core/sharing/app_share_service.dart';
import '../../../core/widgets/sacred_text.dart';
import '../data/liturgy_repository.dart';
import '../domain/liturgy.dart';
import '../domain/liturgy_content.dart';
import 'liturgy_reader_view_model.dart';

class LiturgyReaderScreen extends StatefulWidget {
  const LiturgyReaderScreen({
    required this.liturgy,
    required this.repository,
    required this.preferencesStore,
    super.key,
  });

  final Liturgy liturgy;
  final LiturgyRepository repository;
  final ReaderPreferencesStore preferencesStore;

  @override
  State<LiturgyReaderScreen> createState() => _LiturgyReaderScreenState();
}

class _LiturgyReaderScreenState extends State<LiturgyReaderScreen> {
  late final LiturgyReaderViewModel _viewModel;

  ReaderLanguage _selectedLanguage = ReaderLanguage.all;
  double _textScale = 1;
  bool _highlightSacredNames = true;

  @override
  void initState() {
    super.initState();

    _viewModel = LiturgyReaderViewModel(
      repository: widget.repository,
      slug: widget.liturgy.slug,
    );

    _viewModel.loadContent();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await widget.preferencesStore.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLanguage = preferences.language;
        _textScale = preferences.textScale;
        _highlightSacredNames = preferences.highlightSacredNames;
      });
    } catch (_) {
      // Keep safe defaults when platform preferences cannot be read.
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.liturgy.nameAm.isNotEmpty
        ? widget.liturgy.nameAm
        : widget.liturgy.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<ReaderLanguage>(
            initialValue: _selectedLanguage,
            tooltip: 'ቋንቋ ይምረጡ',
            icon: const Icon(Icons.translate),
            onSelected: (language) {
              setState(() {
                _selectedLanguage = language;
              });
              unawaited(widget.preferencesStore.saveLanguage(language));
            },
            itemBuilder: (context) {
              return [
                CheckedPopupMenuItem(
                  value: ReaderLanguage.all,
                  checked: _selectedLanguage == ReaderLanguage.all,
                  child: const Text('ሁሉም ቋንቋዎች'),
                ),
                CheckedPopupMenuItem(
                  value: ReaderLanguage.geez,
                  checked: _selectedLanguage == ReaderLanguage.geez,
                  child: const Text('ግዕዝ'),
                ),
                CheckedPopupMenuItem(
                  value: ReaderLanguage.amharic,
                  checked: _selectedLanguage == ReaderLanguage.amharic,
                  child: const Text('አማርኛ'),
                ),
                CheckedPopupMenuItem(
                  value: ReaderLanguage.english,
                  checked: _selectedLanguage == ReaderLanguage.english,
                  child: const Text('English'),
                ),
              ];
            },
          ),
          PopupMenuButton<double>(
            initialValue: _textScale,
            tooltip: 'Text size',
            icon: const Icon(Icons.text_fields),
            onSelected: (scale) {
              setState(() {
                _textScale = scale;
              });
              unawaited(widget.preferencesStore.saveTextScale(scale));
            },
            itemBuilder: (context) {
              return [
                CheckedPopupMenuItem(
                  value: 0.9,
                  checked: _textScale == 0.9,
                  child: const Text('Small'),
                ),
                CheckedPopupMenuItem(
                  value: 1.0,
                  checked: _textScale == 1.0,
                  child: const Text('Normal'),
                ),
                CheckedPopupMenuItem(
                  value: 1.2,
                  checked: _textScale == 1.2,
                  child: const Text('Large'),
                ),
                CheckedPopupMenuItem(
                  value: 1.4,
                  checked: _textScale == 1.4,
                  child: const Text('Extra large'),
                ),
              ];
            },
          ),
          IconButton(
            tooltip: 'ይህን ቅዳሴ ያጋሩ',
            onPressed: () => AppShareService.shareLiturgy(widget.liturgy),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            return _buildBody();
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.status) {
      case LiturgyReaderStatus.initial:
      case LiturgyReaderStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case LiturgyReaderStatus.failure:
        return _buildError();

      case LiturgyReaderStatus.success:
        final content = _viewModel.content;

        if (content == null || content.sections.isEmpty) {
          return _buildEmpty();
        }

        return _buildContent(content);
    }
  }

  Widget _buildContent(LiturgyContent content) {
    final items = <Object>[];

    for (final section in content.sections) {
      items.add(section);
      items.addAll(section.verses);
    }

    return RefreshIndicator(
      onRefresh: () => _viewModel.loadContent(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          if (item is LiturgySection) {
            return _buildSectionHeader(item);
          }

          if (item is Verse) {
            return _buildVerse(item);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(LiturgySection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SacredText(
            section.titleAm.isNotEmpty ? section.titleAm : section.title,
            sacredColor: AppTheme.sacredRed,
            enabled: _highlightSacredNames,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24 * _textScale,
              height: 1.4,
              color: AppTheme.controlGreen,
            ),
          ),
          if (section.titleAm.isNotEmpty && section.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              section.title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14 * _textScale),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerse(Verse verse) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = _roleColor(verse.role);
    final showGeez =
        _selectedLanguage == ReaderLanguage.all ||
        _selectedLanguage == ReaderLanguage.geez;
    final showAmharic =
        _selectedLanguage == ReaderLanguage.all ||
        _selectedLanguage == ReaderLanguage.amharic;
    final showEnglish =
        _selectedLanguage == ReaderLanguage.all ||
        _selectedLanguage == ReaderLanguage.english;
    final hasVisibleText =
        (showGeez && verse.textGeez.isNotEmpty) ||
        (showAmharic && verse.textAm.isNotEmpty) ||
        (showEnglish && verse.textEn.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _roleLabel(verse.role),
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (!hasVisibleText) ...[
            const SizedBox(height: 14),
            Text(
              _selectedLanguage == ReaderLanguage.english
                  ? 'Text is unavailable in the selected language.'
                  : 'በተመረጠው ቋንቋ ጽሑፍ አልተገኘም።',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (showGeez && verse.textGeez.isNotEmpty) ...[
            const SizedBox(height: 14),
            SacredText(
              verse.textGeez,
              sacredColor: AppTheme.sacredRed,
              textAlign: TextAlign.justify,
              enabled: _highlightSacredNames,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22 * _textScale,
                height: 1.68,
              ),
            ),
          ],
          if (showAmharic && verse.textAm.isNotEmpty) ...[
            const SizedBox(height: 11),
            SacredText(
              verse.textAm,
              sacredColor: AppTheme.sacredRed,
              textAlign: TextAlign.justify,
              enabled: _highlightSacredNames,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18 * _textScale,
                height: 1.68,
              ),
            ),
          ],
          if (showEnglish && verse.textEn.isNotEmpty) ...[
            const SizedBox(height: 11),
            SacredText(
              verse.textEn,
              sacredColor: AppTheme.sacredRed,
              textAlign: TextAlign.justify,
              enabled: _highlightSacredNames,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16 * _textScale,
                height: 1.58,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(),
        ],
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
              _viewModel.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _viewModel.loadContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'This liturgy does not contain any sections yet.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    if (_selectedLanguage == ReaderLanguage.english) {
      return switch (role) {
        'priest' => 'Priest',
        'assistant_priest' => 'Assistant priest',
        'deacon' => 'Deacon',
        'assistant_deacon' => 'Assistant deacon',
        'congregation' => 'Congregation',
        'chanter' => 'Chanter',
        'reader' => 'Reader',
        'rubric' => 'Instruction',
        'mixed' => 'Multiple roles',
        _ => role.isEmpty ? 'Unknown role' : role,
      };
    }

    return switch (role) {
      'priest' => 'ካህን',
      'assistant_priest' => 'ረዳት ካህን',
      'deacon' => 'ዲያቆን',
      'assistant_deacon' => 'ረዳት ዲያቆን',
      'congregation' => 'ሕዝብ',
      'chanter' => 'መዘምር',
      'reader' => 'አንባቢ',
      'rubric' => 'መመሪያ',
      'mixed' => 'የተለያዩ አገልጋዮች',
      _ => role.isEmpty ? 'ያልታወቀ ሚና' : role,
    };
  }

  Color _roleColor(String role) {
    return switch (role) {
      'priest' || 'assistant_priest' => AppTheme.sacredRed,
      'deacon' || 'assistant_deacon' => AppTheme.controlGreen,
      'congregation' => AppTheme.liturgicalGold,
      'rubric' => Theme.of(context).colorScheme.onSurfaceVariant,
      _ => Theme.of(context).colorScheme.primary,
    };
  }
}
