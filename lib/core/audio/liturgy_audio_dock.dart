import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../localization/app_language.dart';
import 'liturgy_audio_controller.dart';

/// Audio controls docked above the reading area.
///
/// The dock is laid out in the page column rather than floating over the text,
/// so it never covers a prayer. Collapsed it is a single row that shares its
/// space with the page navigation passed in as [middle]; expanded it adds
/// playback speed, the offline download and any error underneath.
class LiturgyAudioDock extends StatefulWidget {
  const LiturgyAudioDock({
    required this.controller,
    required this.appLanguage,
    required this.expanded,
    required this.onExpandedChanged,
    this.middle,
    super.key,
  });

  final LiturgyAudioController controller;
  final AppLanguage appLanguage;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  /// Page navigation that shares the dock's first row, so the controls cost no
  /// extra height. Null on screens without paged content.
  final Widget? middle;

  @override
  State<LiturgyAudioDock> createState() => _LiturgyAudioDockState();
}

class _LiturgyAudioDockState extends State<LiturgyAudioDock> {
  double? _dragPositionMs;

  String _ui({required String amharic, required String english}) {
    return widget.appLanguage.text(amharic: amharic, english: english);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
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
            padding: const EdgeInsets.fromLTRB(14, 4, 8, 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlRow(context, controller),
                _buildSeekBar(context, controller),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: widget.expanded
                      ? _buildPanel(context, controller)
                      : _buildCollapsedStatus(context, controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlRow(
    BuildContext context,
    LiturgyAudioController controller,
  ) {
    final middle = widget.middle;

    return Row(
      children: [
        SizedBox.square(
          dimension: 36,
          child: IconButton.filled(
            padding: EdgeInsets.zero,
            iconSize: 20,
            tooltip: controller.playing
                ? _ui(amharic: 'አቁም', english: 'Pause')
                : _ui(amharic: 'አጫውት', english: 'Play'),
            onPressed: controller.isBuffering
                ? null
                : () => unawaited(controller.togglePlayback()),
            icon: controller.isBuffering
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(
                    controller.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _format(controller.position),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (controller.errorMessage != null && !widget.expanded) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
        if (middle == null)
          const Spacer()
        else ...[
          const SizedBox(width: 10),
          Expanded(child: middle),
        ],
        IconButton(
          tooltip: widget.expanded
              ? _ui(
                  amharic: 'የድምፅ መቆጣጠሪያውን አሳንስ',
                  english: 'Hide audio options',
                )
              : _ui(
                  amharic: 'የድምፅ መቆጣጠሪያውን አሳይ',
                  english: 'Show audio options',
                ),
          onPressed: () => widget.onExpandedChanged(!widget.expanded),
          icon: Icon(
            widget.expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar(
    BuildContext context,
    LiturgyAudioController controller,
  ) {
    final duration = controller.duration;
    final maximum = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final value = (_dragPositionMs ?? controller.position.inMilliseconds)
        .toDouble()
        .clamp(0.0, maximum);

    return SizedBox(
      height: 22,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 6,
            disabledThumbRadius: 4,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: AppTheme.controlGreen,
          thumbColor: AppTheme.controlGreen,
          inactiveTrackColor: AppTheme.liturgicalGold.withValues(alpha: 0.24),
        ),
        child: Slider(
          value: value,
          min: 0,
          max: maximum,
          onChanged: duration == Duration.zero
              ? null
              : (milliseconds) {
                  setState(() {
                    _dragPositionMs = milliseconds;
                  });
                },
          onChangeEnd: duration == Duration.zero
              ? null
              : (milliseconds) {
                  setState(() {
                    _dragPositionMs = null;
                  });
                  unawaited(
                    controller.seek(
                      Duration(milliseconds: milliseconds.round()),
                    ),
                  );
                },
        ),
      ),
    );
  }

  /// Collapsed, only a download still in flight is worth the extra pixels.
  Widget _buildCollapsedStatus(
    BuildContext context,
    LiturgyAudioController controller,
  ) {
    if (!controller.isDownloading) {
      return const SizedBox(width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: LinearProgressIndicator(
        value: controller.downloadProgress == 0
            ? null
            : controller.downloadProgress,
        minHeight: 2,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, LiturgyAudioController controller) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_format(controller.position)} / ${_format(controller.duration)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.isDownloaded
                      ? _ui(amharic: 'ከመስመር ውጭ ዝግጁ', english: 'Ready offline')
                      : _ui(
                          amharic: 'ከበይነመረብ ይጫወታል',
                          english: 'Streams while online',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: controller.isDownloaded
                        ? AppTheme.controlGreen
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              PopupMenuButton<double>(
                initialValue: controller.speed,
                tooltip: _ui(amharic: 'የድምፅ ፍጥነት', english: 'Playback speed'),
                onSelected: (value) => unawaited(controller.setSpeed(value)),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 0.75, child: Text('0.75×')),
                  PopupMenuItem(value: 1.0, child: Text('1×')),
                  PopupMenuItem(value: 1.25, child: Text('1.25×')),
                  PopupMenuItem(value: 1.5, child: Text('1.5×')),
                  PopupMenuItem(value: 2.0, child: Text('2×')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    '${controller.speed.toStringAsFixed(controller.speed == 1 ? 0 : 2)}×',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              IconButton(
                tooltip: controller.isDownloaded
                    ? _ui(
                        amharic: 'የወረደውን ድምፅ አስወግድ',
                        english: 'Remove offline audio',
                      )
                    : _ui(
                        amharic: 'ለመስመር ውጭ አውርድ',
                        english: 'Download for offline use',
                      ),
                onPressed: controller.isDownloading
                    ? null
                    : () => controller.isDownloaded
                          ? unawaited(_confirmRemove(context, controller))
                          : unawaited(controller.download()),
                icon: controller.isDownloading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Icon(
                        controller.isDownloaded
                            ? Icons.offline_pin_rounded
                            : Icons.download_for_offline_outlined,
                        color: AppTheme.controlGreen,
                      ),
              ),
            ],
          ),
          if (controller.isDownloading)
            LinearProgressIndicator(
              value: controller.downloadProgress == 0
                  ? null
                  : controller.downloadProgress,
              minHeight: 3,
              borderRadius: BorderRadius.circular(99),
            ),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _ui(
                  amharic: 'ድምፁን መጫወት ወይም ማውረድ አልተቻለም።',
                  english: 'The audio could not be played or downloaded.',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    LiturgyAudioController controller,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _ui(amharic: 'የወረደውን ድምፅ ይወገድ?', english: 'Remove downloaded audio?'),
        ),
        content: Text(
          _ui(
            amharic: 'በኋላ ከመስመር ውጭ ለማዳመጥ እንደገና ማውረድ ያስፈልጋል።',
            english:
                'You will need to download it again for offline listening.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_ui(amharic: 'ይቅር', english: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_ui(amharic: 'አስወግድ', english: 'Remove')),
          ),
        ],
      ),
    );

    if (remove == true) {
      await controller.removeDownload();
    }
  }

  String _format(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
