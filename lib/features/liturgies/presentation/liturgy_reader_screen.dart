import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
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
    required this.appLanguage,
    super.key,
  });

  final Liturgy liturgy;
  final LiturgyRepository repository;
  final ReaderPreferencesStore preferencesStore;
  final AppLanguage appLanguage;

  @override
  State<LiturgyReaderScreen> createState() => _LiturgyReaderScreenState();
}

class _LiturgyReaderScreenState extends State<LiturgyReaderScreen> {
  late final LiturgyReaderViewModel _viewModel;
  late final PageController _pageController;

  ReaderLanguage _selectedLanguage = ReaderLanguage.all;
  double _textScale = 1;
  bool _highlightSacredNames = true;
  int _currentPageIndex = 0;

  String _ui({required String amharic, required String english}) {
    return widget.appLanguage.text(amharic: amharic, english: english);
  }

  @override
  void initState() {
    super.initState();

    _viewModel = LiturgyReaderViewModel(
      repository: widget.repository,
      slug: widget.liturgy.slug,
    );

    _pageController = PageController();
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amharicTitle = widget.liturgy.nameAm.isNotEmpty
        ? widget.liturgy.nameAm
        : widget.liturgy.name;
    final title = widget.appLanguage.isEnglish
        ? widget.liturgy.name
        : amharicTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<ReaderLanguage>(
            initialValue: _selectedLanguage,
            tooltip: _ui(
              amharic: 'የጽሑፍ ቋንቋ ይምረጡ',
              english: 'Choose content language',
            ),
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
                  child: Text(
                    _ui(amharic: 'ሁሉም ቋንቋዎች', english: 'All languages'),
                  ),
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
            tooltip: _ui(amharic: 'የፊደል መጠን', english: 'Text size'),
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
                  child: Text(_ui(amharic: 'ትንሽ', english: 'Small')),
                ),
                CheckedPopupMenuItem(
                  value: 1.0,
                  checked: _textScale == 1.0,
                  child: Text(_ui(amharic: 'መደበኛ', english: 'Normal')),
                ),
                CheckedPopupMenuItem(
                  value: 1.2,
                  checked: _textScale == 1.2,
                  child: Text(_ui(amharic: 'ትልቅ', english: 'Large')),
                ),
                CheckedPopupMenuItem(
                  value: 1.4,
                  checked: _textScale == 1.4,
                  child: Text(_ui(amharic: 'በጣም ትልቅ', english: 'Extra large')),
                ),
              ];
            },
          ),
          IconButton(
            tooltip: _ui(amharic: 'ይዘቱን አድስ', english: 'Refresh content'),
            onPressed: () => _viewModel.loadContent(refresh: true),
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: _ui(amharic: 'ይህን ቅዳሴ ያጋሩ', english: 'Share this liturgy'),
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
    final pages = _groupIntoReaderPages(content);

    if (pages.isEmpty) {
      return _buildEmpty();
    }

    final selectedIndex = _currentPageIndex < pages.length
        ? _currentPageIndex
        : pages.length - 1;

    if (selectedIndex != _currentPageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _pageController.jumpToPage(selectedIndex);
        setState(() {
          _currentPageIndex = selectedIndex;
        });
      });
    }

    return Column(
      children: [
        _buildPagePicker(pages, selectedIndex),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            physics: const PageScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildBookPageTransition(page: pages[index], index: index);
            },
          ),
        ),
        _buildPageFooter(pages, selectedIndex),
      ],
    );
  }

  List<_ReaderPage> _groupIntoReaderPages(LiturgyContent content) {
    final pages = <_ReaderPage>[];

    for (final section in content.sections) {
      _ReaderPage? currentPage;
      var isFirstPageInSection = true;

      for (final verse in section.verses) {
        if (currentPage == null || currentPage.sourcePage != verse.sourcePage) {
          currentPage = _ReaderPage(
            section: section,
            sourcePage: verse.sourcePage,
            showSectionHeader: isFirstPageInSection,
            verses: [verse],
          );
          pages.add(currentPage);
          isFirstPageInSection = false;
        } else {
          currentPage.verses.add(verse);
        }
      }
    }

    return pages;
  }

  Widget _buildPagePicker(List<_ReaderPage> pages, int selectedIndex) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.liturgicalGold.withValues(alpha: 0.32),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 22,
              color: AppTheme.controlGreen,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedIndex,
                  isExpanded: true,
                  menuMaxHeight: 420,
                  borderRadius: BorderRadius.circular(18),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onChanged: (index) {
                    if (index != null) {
                      _goToPage(index, pages.length);
                    }
                  },
                  items: List.generate(pages.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        _pageLabel(pages[index], index),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedIndex + 1} / ${pages.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookPageTransition({
    required _ReaderPage page,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _pageController,
      child: _buildBookPage(page, index),
      builder: (context, child) {
        var position = _currentPageIndex.toDouble();

        if (_pageController.hasClients &&
            _pageController.position.hasContentDimensions) {
          position = _pageController.page ?? position;
        }

        final distance = (position - index).clamp(-1.0, 1.0).toDouble();
        final turnAmount = distance * 0.055;

        return Transform(
          alignment: distance > 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(turnAmount),
          child: Opacity(opacity: 1 - (distance.abs() * 0.1), child: child),
        );
      },
    );
  }

  Widget _buildBookPage(_ReaderPage page, int index) {
    return RefreshIndicator(
      onRefresh: () => _viewModel.loadContent(refresh: true),
      child: ListView(
        key: PageStorageKey<String>(
          'reader-${page.section.id}-${page.sourcePage ?? index}',
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (page.showSectionHeader) _buildSectionHeader(page.section),
          for (final verse in page.verses) _buildVerse(verse),
        ],
      ),
    );
  }

  Widget _buildPageFooter(List<_ReaderPage> pages, int selectedIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFirst = selectedIndex == 0;
    final isLast = selectedIndex == pages.length - 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        border: Border(
          top: BorderSide(
            color: AppTheme.liturgicalGold.withValues(alpha: 0.32),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: (selectedIndex + 1) / pages.length,
              minHeight: 2,
              backgroundColor: AppTheme.liturgicalGold.withValues(alpha: 0.15),
              color: AppTheme.controlGreen,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isFirst
                        ? null
                        : () => _goToPage(selectedIndex - 1, pages.length),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(_ui(amharic: 'ቀዳሚ', english: 'Previous')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isLast
                        ? null
                        : () => _goToPage(selectedIndex + 1, pages.length),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_ui(amharic: 'ቀጣይ', english: 'Next')),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int index, int pageCount) {
    if (index < 0 || index >= pageCount || index == _currentPageIndex) {
      return;
    }

    if (!_pageController.hasClients) {
      setState(() {
        _currentPageIndex = index;
      });
      return;
    }

    if ((index - _currentPageIndex).abs() > 3) {
      _pageController.jumpToPage(index);
      return;
    }

    unawaited(
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  String _pageLabel(_ReaderPage page, int index) {
    final number = page.sourcePage ?? index + 1;

    return widget.appLanguage.isEnglish
        ? 'Page $number'
        : 'ገጽ $number';
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
              _ui(
                amharic: 'በተመረጠው ቋንቋ ጽሑፍ አልተገኘም።',
                english: 'Text is unavailable in the selected language.',
              ),
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
              widget.appLanguage.isEnglish
                  ? (_viewModel.errorMessage ?? 'Something went wrong.')
                  : 'ይዘቱን መጫን አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _viewModel.loadContent,
              icon: const Icon(Icons.refresh),
              label: Text(_ui(amharic: 'እንደገና ሞክር', english: 'Try again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _ui(
            amharic: 'ይህ ቅዳሴ እስካሁን ምንም ክፍል የለውም።',
            english: 'This liturgy does not contain any sections yet.',
          ),
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

final class _ReaderPage {
  _ReaderPage({
    required this.section,
    required this.sourcePage,
    required this.showSectionHeader,
    required this.verses,
  });

  final LiturgySection section;
  final int? sourcePage;
  final bool showSectionHeader;
  final List<Verse> verses;
}
