import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../../core/widgets/sacred_text.dart';
import '../domain/liturgy_content.dart';

class LiturgyGuideCardReader extends StatefulWidget {
  const LiturgyGuideCardReader({
    required this.content,
    required this.selectedLanguage,
    required this.textScale,
    required this.highlightSacredNames,
    required this.appLanguage,
    super.key,
  });

  final LiturgyContent content;
  final ReaderLanguage selectedLanguage;
  final double textScale;
  final bool highlightSacredNames;
  final AppLanguage appLanguage;

  @override
  State<LiturgyGuideCardReader> createState() => _LiturgyGuideCardReaderState();
}

class _LiturgyGuideCardReaderState extends State<LiturgyGuideCardReader> {
  static const _targetChunkLength = 380;

  late final PageController _controller;
  int _currentIndex = 0;

  String _ui({required String amharic, required String english}) {
    return widget.appLanguage.text(amharic: amharic, english: english);
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void didUpdateWidget(covariant LiturgyGuideCardReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLanguage != widget.selectedLanguage) {
      _currentIndex = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _buildCards();
    if (cards.isEmpty) {
      return _buildUnavailable();
    }

    final selectedIndex = _currentIndex.clamp(0, cards.length - 1);
    if (selectedIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.jumpToPage(selectedIndex);
        setState(() => _currentIndex = selectedIndex);
      });
    }

    return Column(
      children: [
        _buildHeader(selectedIndex, cards.length),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: cards.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => _buildAnimatedCard(
              card: cards[index],
              index: index,
              cardCount: cards.length,
            ),
          ),
        ),
        _buildFooter(selectedIndex, cards.length),
      ],
    );
  }

  List<_GuideCardData> _buildCards() {
    final cards = <_GuideCardData>[];

    for (final section in widget.content.sections) {
      for (final verse in section.verses) {
        final visibleTexts = <_VisibleGuideText>[
          if (_shows(ReaderLanguage.geez) && verse.textGeez.trim().isNotEmpty)
            _VisibleGuideText(languageLabel: 'ግዕዝ', text: verse.textGeez),
          if (_shows(ReaderLanguage.amharic) && verse.textAm.trim().isNotEmpty)
            _VisibleGuideText(languageLabel: 'አማርኛ', text: verse.textAm),
          if (_shows(ReaderLanguage.english) && verse.textEn.trim().isNotEmpty)
            _VisibleGuideText(languageLabel: 'English', text: verse.textEn),
        ];
        final kind = (verse.sourceKind ?? 'liturgy-guide:paragraph')
            .split(':')
            .last;

        for (final visibleText in visibleTexts) {
          final chunks = kind == 'heading'
              ? [visibleText.text.trim()]
              : _splitAtWordBoundaries(visibleText.text);

          for (var part = 0; part < chunks.length; part++) {
            cards.add(
              _GuideCardData(
                sourcePage: verse.sourcePage,
                kind: kind,
                languageLabel: visibleText.languageLabel,
                text: chunks[part],
                chunkIndex: part,
                chunkCount: chunks.length,
              ),
            );
          }
        }
      }
    }
    return cards;
  }

  bool _shows(ReaderLanguage language) {
    return widget.selectedLanguage == ReaderLanguage.all ||
        widget.selectedLanguage == language;
  }

  List<String> _splitAtWordBoundaries(String value) {
    final chunks = <String>[];
    var current = StringBuffer();

    for (final word in value.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final nextLength =
          current.length + (current.isEmpty ? 0 : 1) + word.length;
      if (current.isNotEmpty && nextLength > _targetChunkLength) {
        chunks.add(current.toString());
        current = StringBuffer();
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(word);
    }

    if (current.isNotEmpty) chunks.add(current.toString());
    return chunks;
  }

  Widget _buildHeader(int selectedIndex, int cardCount) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, color: AppTheme.controlGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _ui(
                amharic: 'ካርዱን ይንኩ ወይም ያንሸራትቱ',
                english: 'Tap the card or swipe to continue',
              ),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            '${selectedIndex + 1} / $cardCount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.controlGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({
    required _GuideCardData card,
    required int index,
    required int cardCount,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      child: _buildCard(card, index, cardCount),
      builder: (context, child) {
        var position = _currentIndex.toDouble();
        if (_controller.hasClients &&
            _controller.position.hasContentDimensions) {
          position = _controller.page ?? position;
        }
        final distance = (position - index).clamp(-1.0, 1.0).toDouble();

        return Transform.rotate(
          angle: distance * 0.018,
          child: Transform.scale(
            scale: 1 - distance.abs() * 0.07,
            child: Opacity(opacity: 1 - distance.abs() * 0.28, child: child),
          ),
        );
      },
    );
  }

  Widget _buildCard(_GuideCardData card, int index, int cardCount) {
    final theme = Theme.of(context);
    final isHeading = card.kind == 'heading';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 540),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: index == cardCount - 1
              ? null
              : () => _goToCard(index + 1, cardCount),
          child: Container(
            margin: const EdgeInsets.fromLTRB(6, 18, 6, 22),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            decoration: BoxDecoration(
              color: AppTheme.parchmentSurface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppTheme.liturgicalGold.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.inkBlack.withValues(alpha: 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTypeBadge(card.kind),
                    const Spacer(),
                    Text(
                      card.languageLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (card.sourcePage != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        _ui(
                          amharic: 'ገጽ ${card.sourcePage}',
                          english: 'Page ${card.sourcePage}',
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (card.chunkCount > 1) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      '${card.chunkIndex + 1}/${card.chunkCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.liturgicalGold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: SacredText(
                        card.text,
                        sacredColor: AppTheme.sacredRed,
                        enabled: widget.highlightSacredNames,
                        textAlign: isHeading
                            ? TextAlign.center
                            : TextAlign.justify,
                        style:
                            (isHeading
                                    ? theme.textTheme.headlineSmall
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(
                                  fontSize:
                                      (isHeading ? 24 : 18) * widget.textScale,
                                  height: isHeading ? 1.5 : 1.68,
                                  color: AppTheme.inkBlack,
                                ),
                      ),
                    ),
                  ),
                ),
                if (index < cardCount - 1) ...[
                  const SizedBox(height: 12),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 20,
                    color: AppTheme.liturgicalGold.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String kind) {
    final (icon, label) = switch (kind) {
      'heading' => (
        Icons.title_rounded,
        _ui(amharic: 'ርዕስ', english: 'Heading'),
      ),
      'list_item' => (
        Icons.format_list_bulleted_rounded,
        _ui(amharic: 'ዝርዝር', english: 'List'),
      ),
      _ => (Icons.notes_rounded, _ui(amharic: 'ማብራሪያ', english: 'Explanation')),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.controlGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.controlGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.controlGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int selectedIndex, int cardCount) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: (selectedIndex + 1) / cardCount,
          minHeight: 4,
          backgroundColor: AppTheme.liturgicalGold.withValues(alpha: 0.16),
          color: AppTheme.controlGreen,
        ),
      ),
    );
  }

  void _goToCard(int index, int cardCount) {
    if (index < 0 || index >= cardCount || index == _currentIndex) return;

    if (!_controller.hasClients) {
      setState(() => _currentIndex = index);
      return;
    }

    unawaited(
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 46,
              color: AppTheme.controlGreen,
            ),
            const SizedBox(height: 14),
            Text(
              _ui(
                amharic: 'በተመረጠው ቋንቋ የመግቢያ ጽሑፍ አልተገኘም።',
                english:
                    'Guide content is unavailable in the selected language.',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _VisibleGuideText {
  const _VisibleGuideText({required this.languageLabel, required this.text});

  final String languageLabel;
  final String text;
}

final class _GuideCardData {
  const _GuideCardData({
    required this.sourcePage,
    required this.kind,
    required this.languageLabel,
    required this.text,
    required this.chunkIndex,
    required this.chunkCount,
  });

  final int? sourcePage;
  final String kind;
  final String languageLabel;
  final String text;
  final int chunkIndex;
  final int chunkCount;
}
