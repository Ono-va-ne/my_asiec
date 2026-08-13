import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VoiceMessageWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const VoiceMessageWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      try {
        setState(() => _isBuffering = true);

        // 1. Достаем имя файла из URL
        final fileName = widget.audioUrl.split('/').last;
        final tempDir = await getTemporaryDirectory();
        final localFile = File('${tempDir.path}/$fileName');

        // 2. Если аудио еще не скачано — скачиваем во временный кэш
        if (!await localFile.exists()) {
          final response = await http.get(Uri.parse(widget.audioUrl));
          await localFile.writeAsBytes(response.bodyBytes);
        }

        if (mounted) setState(() => _isBuffering = false);

        // 3. Воспроизводим ЛОКАЛЬНЫЙ файл (100% надежно для Android!)
        await _player.play(DeviceFileSource(localFile.path));
      } catch (e) {
        print('Ошибка воспроизведения ГС: $e');
        if (mounted) {
          setState(() => _isBuffering = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка воспроизведения: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          // Кнопка Play / Pause / Загрузка
          _isBuffering
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                padding: EdgeInsets.zero,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: widget.isMe ? Theme.of(context).colorScheme.onPrimary : Colors.blue,
                    size: 48,
                  ),
                  onPressed: _togglePlay,
                ),

          // Прогресс-бар и Таймер
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: CustomHandleThumbShape(thumbHeight: 20),
                    thumbSize: WidgetStateProperty.all(Size(5.0, 15.0)),
                    trackHeight: 10,
                  ),
                  child: Slider(
                    year2023: false,
                    value: progress.clamp(0.0, 1.0),
                    activeColor: widget.isMe ? Theme.of(context).colorScheme.onPrimary : Colors.blue,
                    inactiveColor: widget.isMe ? Theme.of(context).colorScheme.onPrimary.withAlpha(100) : Colors.grey.shade300,
                    onChanged: (val) {
                      final targetMs = (val * _duration.inMilliseconds).toInt();
                      _player.seek(Duration(milliseconds: targetMs));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    _isPlaying ? _formatDuration(_position) : _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isMe ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomHandleThumbShape extends SliderComponentShape {
  // Задаем желаемую высоту через конструктор
  final double thumbHeight;

  const CustomHandleThumbShape({this.thumbHeight = 24.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isPressed) {
    // Встроенная логика HandleThumbShape меняет ширину при нажатии
    final double width = isPressed ? 2.0 : 4.0;
    return Size(width, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    // Рассчитываем анимацию изменения ширины при нажатии (как в оригинале)
    final double status = activationAnimation.value;
    final double width = lerpDouble(4.0, 2.0, status)!;

    // Determine the thumb color based on enableAnimation and sliderTheme.
    final Color color = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;

    // Определяем прямоугольник ползунка с кастомной высотой
    final Rect rect = Rect.fromCenter(
      center: center,
      width: width,
      height: thumbHeight,
    );

    // Скругляем углы (радиус равен половине ширины)
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(width / 2));

    final Paint paint = Paint()..color = color;

    canvas.drawRRect(rrect, paint);
  }
}