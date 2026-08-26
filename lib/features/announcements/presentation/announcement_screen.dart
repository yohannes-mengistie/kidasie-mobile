import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/history/reading_history.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/preferences/reader_preferences.dart';
import '../../liturgies/data/liturgy_repository.dart';
import '../../liturgies/domain/liturgy.dart';
import '../../liturgies/presentation/liturgy_reader_screen.dart';
import '../data/announcement_read_store.dart';
import '../data/announcement_repository.dart';
import '../domain/announcement.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({
    required this.repository,
    required this.readStore,
    required this.liturgyRepository,
    required this.preferencesStore,
    required this.historyStore,
    required this.appLanguage,
    required this.onUnreadCountChanged,
    super.key,
  });

  final AnnouncementRepository repository;
  final AnnouncementReadStore readStore;
  final LiturgyRepository liturgyRepository;
  final ReaderPreferencesStore preferencesStore;
  final ReadingHistoryStore historyStore;
  final AppLanguage appLanguage;
  final ValueChanged<int> onUnreadCountChanged;

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Announcement> _announcements = const [];
  Map<String, int> _readVersions = const {};
  bool _loading = true;
  bool _refreshing = false;
  Object? _error;

  String _ui({required String amharic, required String english}) =>
      widget.appLanguage.text(amharic: amharic, english: english);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final readVersions = await widget.readStore.loadReadVersions();
    try {
      final cached = await widget.repository.getAnnouncements();
      if (!mounted) return;
      _apply(cached, readVersions: readVersions, loading: false);
      unawaited(_refresh(silent: true));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _readVersions = readVersions;
        _loading = false;
        _error = error;
      });
      _notifyUnread();
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    if (mounted) {
      setState(() {
        _refreshing = true;
        if (!silent && _announcements.isEmpty) _loading = true;
      });
    }

    try {
      final announcements = await widget.repository.getAnnouncements(
        refresh: true,
      );
      final readVersions = await widget.readStore.loadReadVersions();
      if (!mounted) return;
      _apply(announcements, readVersions: readVersions, loading: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
      if (!silent && _announcements.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ui(
                amharic: 'አዲስ ማስታወቂያ መፈለግ አልተቻለም። የተቀመጠው ዝርዝር ይታያል።',
                english:
                    'Could not check for updates. Showing saved announcements.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _apply(
    List<Announcement> announcements, {
    required Map<String, int> readVersions,
    required bool loading,
  }) {
    setState(() {
      _announcements = announcements;
      _readVersions = readVersions;
      _loading = loading;
      _error = null;
    });
    _notifyUnread();
  }

  void _notifyUnread() {
    final count = widget.readStore.countUnread(_announcements, _readVersions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onUnreadCountChanged(count);
    });
  }

  Future<void> _openAnnouncement(Announcement announcement) async {
    await widget.readStore.markRead(announcement);
    if (!mounted) return;
    setState(() {
      _readVersions = {
        ..._readVersions,
        announcement.slug: announcement.version,
      };
    });
    _notifyUnread();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _AnnouncementDetails(
        announcement: announcement,
        appLanguage: widget.appLanguage,
        onAction: announcement.action.isAvailable
            ? () {
                Navigator.pop(sheetContext);
                unawaited(_runAction(announcement));
              }
            : null,
      ),
    );
  }

  Future<void> _runAction(Announcement announcement) async {
    switch (announcement.action.type) {
      case 'open_liturgy':
        await _openLiturgy(announcement.action.value);
      case 'open_url':
      case 'download_apk':
        await _openExternalUrl(announcement.action.value);
      case 'none':
        return;
      default:
        _showActionError();
    }
  }

  Future<void> _openLiturgy(String slug) async {
    try {
      final liturgies = await widget.liturgyRepository.getLiturgies();
      Liturgy? liturgy;
      for (final candidate in liturgies) {
        if (candidate.slug == slug) {
          liturgy = candidate;
          break;
        }
      }
      if (liturgy == null || !mounted) {
        _showActionError();
        return;
      }
      await widget.historyStore.record(liturgy);
      if (!mounted) return;
      final selectedLiturgy = liturgy;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => LiturgyReaderScreen(
            repository: widget.liturgyRepository,
            liturgy: selectedLiturgy,
            preferencesStore: widget.preferencesStore,
            appLanguage: widget.appLanguage,
          ),
        ),
      );
    } catch (_) {
      _showActionError();
    }
  }

  Future<void> _openExternalUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showActionError();
    }
  }

  void _showActionError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _ui(
            amharic: 'ይህን አገናኝ አሁን መክፈት አልተቻለም።',
            english: 'This link could not be opened right now.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ui(amharic: 'ማስታወቂያ', english: 'Announcements')),
        actions: [
          IconButton(
            tooltip: _ui(amharic: 'አድስ', english: 'Refresh'),
            onPressed: _refreshing ? null : () => unawaited(_refresh()),
            icon: _refreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.parchment,
                Color(0xFFF8EFD9),
                Color(0xFFEFE0C1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_announcements.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 90),
            Icon(
              _error == null
                  ? Icons.notifications_none_rounded
                  : Icons.cloud_off_rounded,
              size: 62,
              color: AppTheme.controlGreen.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 18),
            Text(
              _error == null
                  ? _ui(
                      amharic: 'እስካሁን ማስታወቂያ የለም',
                      english: 'No announcements yet',
                    )
                  : _ui(
                      amharic: 'ማስታወቂያዎችን መጫን አልተቻለም',
                      english: 'Announcements could not be loaded',
                    ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _ui(
                amharic: 'ኢንተርኔት ሲኖር ወደ ታች ጎትተው እንደገና ይሞክሩ።',
                english: 'Pull down to try again when you have internet.',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        itemCount: _announcements.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AnnouncementHero(appLanguage: widget.appLanguage);
          }
          final announcement = _announcements[index - 1];
          return _AnnouncementCard(
            announcement: announcement,
            appLanguage: widget.appLanguage,
            isUnread: widget.readStore.isUnread(announcement, _readVersions),
            onTap: () => unawaited(_openAnnouncement(announcement)),
          );
        },
      ),
    );
  }
}

class _AnnouncementHero extends StatelessWidget {
  const _AnnouncementHero({required this.appLanguage});

  final AppLanguage appLanguage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.parchmentSurface.withValues(alpha: 0.94),
                const Color(0xFFDDE7DC).withValues(alpha: 0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.liturgicalGold.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.controlGreen,
                foregroundColor: Colors.white,
                child: Icon(Icons.campaign_rounded),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLanguage.text(
                        amharic: 'ከቅዳሴ መተግበሪያ',
                        english: 'From Orthodox Liturgy',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appLanguage.text(
                        amharic: 'አዲስ ይዘት፣ ድምፅ እና የመተግበሪያ ዜና',
                        english: 'New content, audio, and app news',
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
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.appLanguage,
    required this.isUnread,
    required this.onTap,
  });

  final Announcement announcement;
  final AppLanguage appLanguage;
  final bool isUnread;
  final VoidCallback onTap;

  IconData get _icon => switch (announcement.kind) {
    'content' => Icons.menu_book_rounded,
    'audio' => Icons.headphones_rounded,
    'app_update' => Icons.system_update_rounded,
    'important' => Icons.priority_high_rounded,
    _ => Icons.notifications_rounded,
  };

  Color get _color => switch (announcement.kind) {
    'important' => AppTheme.sacredRed,
    'app_update' => const Color(0xFF315A78),
    'audio' => const Color(0xFF76511B),
    _ => AppTheme.controlGreen,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: AppTheme.parchmentSurface.withValues(alpha: 0.78),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isUnread
                      ? _color.withValues(alpha: 0.5)
                      : AppTheme.warmOutline.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _color.withValues(alpha: 0.13),
                    foregroundColor: _color,
                    child: Icon(_icon),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title(appLanguage),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (announcement.isPinned)
                              Icon(
                                Icons.push_pin_rounded,
                                size: 17,
                                color: _color,
                              ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: _color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          announcement.body(appLanguage),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 9),
                        Text(
                          MaterialLocalizations.of(context).formatMediumDate(
                            announcement.publishedAt.toLocal(),
                          ),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.inkBlack.withValues(
                                  alpha: 0.58,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementDetails extends StatelessWidget {
  const _AnnouncementDetails({
    required this.announcement,
    required this.appLanguage,
    required this.onAction,
  });

  final Announcement announcement;
  final AppLanguage appLanguage;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = switch (announcement.action.type) {
      'open_liturgy' => appLanguage.text(
        amharic: 'ቅዳሴውን ክፈት',
        english: 'Open liturgy',
      ),
      'download_apk' => appLanguage.text(
        amharic: 'አዲሱን APK አውርድ',
        english: 'Download new APK',
      ),
      _ => appLanguage.text(amharic: 'አገናኙን ክፈት', english: 'Open link'),
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.isPinned)
                const Icon(Icons.push_pin_rounded, color: AppTheme.sacredRed),
              Text(
                announcement.title(appLanguage),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SelectableText(
                announcement.body(appLanguage),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (onAction != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(actionLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
