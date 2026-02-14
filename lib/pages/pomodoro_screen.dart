// import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/pomodoro_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  void initState() {
    super.initState();
    // Запрашиваем разрешения при открытии экрана
    NotificationService().requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Таймер'),
              actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Редактировать',
            onPressed: pomodoroService.resetAll,
          ),
        ],

      ),
      body: ValueListenableBuilder<bool>(
        // Слушаем isTimerRunning, чтобы перерисовывать кнопки и др.
        valueListenable: pomodoroService.isTimerRunning,
        builder: (context, isRunning, _) {
          return ValueListenableBuilder<int>(
            // Слушаем оставшееся время
            valueListenable: pomodoroService.remainingTime,
            builder: (context, remainingTime, _) {
              final currentDuration = pomodoroService.currentDuration;
              final progress = currentDuration > 0 ? 1 - (remainingTime / currentDuration) : 0.0;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder<PomodoroSession>(
                      valueListenable: pomodoroService.currentSession,
                      builder: (context, session, _) => Text(
                        pomodoroService.sessionTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                          Center(
                            child: Text(
                              pomodoroService.formatTime(remainingTime),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Кнопка сброса
                        IconButton.filledTonal(
                          iconSize: 40,
                          onPressed: pomodoroService.resetTimer,
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(80, 80),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Кнопка старт/пауза
                        IconButton.filled(
                          iconSize: 56,
                          onPressed: isRunning ? pomodoroService.pauseTimer : pomodoroService.startTimer,
                          icon: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(100, 100),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Кнопка "следующий"
                        IconButton.filledTonal(
                          iconSize: 40,
                          onPressed: pomodoroService.moveToNextSession,
                          icon: const Icon(Icons.skip_next),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(80, 80),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<int>(
                      valueListenable: pomodoroService.workSessionCount,
                      builder: (context, count, _) => Text(
                        'Циклов завершено: $count',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pomodoro-fab', // Уникальный тег для кнопки
        onPressed: () => _showSettingsDialog(context),
        label: const Text('Настроить'),
        icon: const Icon(Icons.settings_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Настройка интервалов'),
          content: SingleChildScrollView(
            child: _buildPomodoroSettings(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Закрыть'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Хелпер для настроек Pomodoro (скопирован из settings_screen.dart)
  Widget _buildPomodoroSettings() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: settingsService.pomodoroWorkDurationNotifier,
          builder: (context, workMinutes, _) {
            return _buildDurationSliderTile(
              title: 'Рабочий цикл',
              icon: Icons.work_outline,
              currentValue: workMinutes,
              onChanged: (newValue) {
                settingsService.setPomodoroWorkDuration(newValue.round());
              },
              min: 5,
              max: 90,
              divisions: (90 - 5) ~/ 5, // Шаг 5 минут
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: settingsService.pomodoroShortBreakDurationNotifier,
          builder: (context, breakMinutes, _) {
            return _buildDurationSliderTile(
              title: 'Короткий перерыв',
              icon: Icons.free_breakfast_outlined,
              currentValue: breakMinutes,
              onChanged: (newValue) {
                settingsService.setPomodoroShortBreakDuration(newValue.round());
              },
              min: 1,
              max: 18,
              divisions: 17, // Шаг 1 минута
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: settingsService.pomodoroLongBreakDurationNotifier,
          builder: (context, breakMinutes, _) {
            return _buildDurationSliderTile(
              title: 'Длинный перерыв',
              icon: Icons.bedtime_outlined,
              currentValue: breakMinutes,
              onChanged: (newValue) {
                settingsService.setPomodoroLongBreakDuration(newValue.round());
              },
              min: 3,
              max: 30,
              divisions: (30 - 3) ~/ 3, // Шаг 5 минут
            );
          },
        ),
      ],
    );
  }

  // Хелпер для создания ListTile со слайдером (скопирован из settings_screen.dart)
  Widget _buildDurationSliderTile({
    required String title,
    required IconData icon,
    required int currentValue,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    required int divisions,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text('$currentValue мин.'),
        ),
        Slider(
          value: currentValue.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: '$currentValue мин.',
          onChanged: onChanged,
        ),
      ],
    );
  }
}