import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../localization/app_language.dart';
import 'liturgy_audio_controller.dart';

class LiturgyAudioPlayer extends StatefulWidget {
  const LiturgyAudioPlayer({
    required this.controller,
    required this.appLanguage,
    required this.isMinimized,
    required this.onMinimizedChanged,
    super.key,
  });

  final LiturgyAudioController controller;
  final AppLanguage appLanguage;
  final bool isMinimized;
  final ValueChanged<bool> onMinimizedChanged;

  @override
  State<LiturgyAudioPlayer> createState() => _LiturgyAudioPlayerState();
}

class _LiturgyAudioPlayerState extends State<LiturgyAudioPlayer> {
  double? _dragPositionMs;

  String _ui({required String amharic, required String english}) {
    return widget.appLanguage.text(amharic: amharic, english: english);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final duration = controller.duration;
        final maximum = duration.inMilliseconds > 0
            ? duration.inMilliseconds.toDouble()
            : 1.0;
        final value = (_dragPositionMs ?? controller.position.inMilliseconds)
            .clamp(0, maximum.toInt())
            .toDouble();
        if (widget.isMinimized) {
          return _buildMinimized(context, controller);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
              decoration: BoxDecoration(
                color: AppTheme.parchmentSurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkBlack.withValues(alpha: 0.16),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 44,
                        child: IconButton.filled(
                          onPressed: controller.isBuffering
                              ? null
                              : () => unawaited(controller.togglePlayback()),
                          icon: controller.isBuffering
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(
                                  controller.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ui(
                                amharic: 'ሙሉ የቅዳሴ ድምፅ',
                                english: 'Complete liturgy audio',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              controller.isDownloaded
                                  ? _ui(
                                      amharic: 'ከመስመር ውጭ ዝግጁ',
                                      english: 'Ready offline',
                                    )
                                  : _ui(
                                      amharic: 'ከበይነመረብ ይጫወታል',
                                      english: 'Streams while online',
                                    ),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: controller.isDownloaded
                                        ? AppTheme.controlGreen
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _ui(
                          amharic: 'የድምፅ መቆጣጠሪያውን አሳንስ',
                          english: 'Minimize audio controls',
                        ),
                        onPressed: () => widget.onMinimizedChanged(true),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      PopupMenuButton<double>(
                        initialValue: controller.speed,
                        tooltip: _ui(
                          amharic: 'የድምፅ ፍጥነት',
                          english: 'Playback speed',
                        ),
                        onSelected: (value) =>
                            unawaited(controller.setSpeed(value)),
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
                            vertical: 10,
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
                                  ? unawaited(
                                      _confirmRemove(context, controller),
                                    )
                                  : unawaited(controller.download()),
                        icon: controller.isDownloading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
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
                  Row(
                    children: [
                      Text(
                        _format(controller.position),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Expanded(
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
                                      Duration(
                                        milliseconds: milliseconds.round(),
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),
                      Text(
                        _format(duration),
                        style: Theme.of(context).textTheme.labelSmall,
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
                          english:
                              'The audio could not be played or downloaded.',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimized(
    BuildContext context,
    LiturgyAudioController controller,
  ) {
    final duration = controller.duration;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (controller.position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 296),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(9, 8, 7, 7),
              decoration: BoxDecoration(
                color: AppTheme.parchmentSurface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkBlack.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 42,
                        child: IconButton.filled(
                          tooltip: controller.playing
                              ? _ui(amharic: 'አቁም', english: 'Pause')
                              : _ui(amharic: 'አጫውት', english: 'Play'),
                          onPressed: controller.isBuffering
                              ? null
                              : () => unawaited(controller.togglePlayback()),
                          icon: controller.isBuffering
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Icon(
                                  controller.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ui(
                                amharic: 'የቅዳሴ ድምፅ',
                                english: 'Liturgy audio',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_format(controller.position)} / ${_format(duration)}',
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _ui(
                          amharic: 'የድምፅ መቆጣጠሪያውን አስፋ',
                          english: 'Expand audio controls',
                        ),
                        onPressed: () => widget.onMinimizedChanged(false),
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: controller.isBuffering ? null : progress,
                      minHeight: 3,
                      backgroundColor: AppTheme.liturgicalGold.withValues(
                        alpha: 0.14,
                      ),
                      color: controller.errorMessage == null
                          ? AppTheme.controlGreen
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (controller.isDownloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(
                        value: controller.downloadProgress == 0
                            ? null
                            : controller.downloadProgress,
                        minHeight: 2,
                        borderRadius: BorderRadius.circular(99),
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
