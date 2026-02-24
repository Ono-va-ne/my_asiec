// import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart'; // Убедитесь, что этот импорт нужен, если используется NotificationService
import '../services/settings_service.dart';
import '../services/pomodoro_service.dart';
import '../l10n/app_localizations.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Передаем локализации в сервис, как только контекст становится доступен.
    // Это гарантирует, что сервис сможет их использовать.
    pomodoroService.setLocalizations(AppLocalizations.of(context)!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;


    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pomodoroTimer),
              actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reset,
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
              final progress = currentDuration > 0
                  ? 1 - (remainingTime / currentDuration)
                  : 0.0;

              // --- ОБЩИЕ ВИДЖЕТЫ ---
              final titleWidget = ValueListenableBuilder<PomodoroSession>(
                valueListenable: pomodoroService.currentSession,
                builder: (context, session, _) => TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    end: session == PomodoroSession.work
                        ? theme.colorScheme.primary
                        : session == PomodoroSession.shortBreak
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.tertiary,
                  ),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, color, child) {
                    return Text(
                      pomodoroService.sessionTitle,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontVariations: [const FontVariation('wdth', 150)],
                        color: color,
                      ),
                    );
                  },
                ),
              );

              final timerWidget = SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                          end: pomodoroService.currentSession.value ==
                                  PomodoroSession.work
                              ? theme.colorScheme.primary
                              : pomodoroService.currentSession.value ==
                                      PomodoroSession.shortBreak
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.tertiary),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, color, child) {
                        return CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 18,
                          year2023: false,
                          backgroundColor: color?.withAlpha(50),
                          valueColor: AlwaysStoppedAnimation<Color?>(color),
                        );
                      },
                    ),
                    Center(
                      child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                              end: pomodoroService.currentSession.value ==
                                      PomodoroSession.work
                                  ? theme.colorScheme.primary
                                  : pomodoroService.currentSession.value ==
                                          PomodoroSession.shortBreak
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.tertiary),
                          duration: const Duration(milliseconds: 250),
                          builder: (context, color, child) {
                            return Text(
                              pomodoroService.formatTime(remainingTime),
                              style: TextStyle(
                                fontFamily: 'Google Sans Flex',
                                fontWeight: FontWeight.w700,
                                fontSize: 72,
                                fontVariations: const [FontVariation('ROND', 50)],
                                color: color,
                              ),
                            );
                          }),
                    ),
                  ],
                ),
              );


              final infoPanel = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: pomodoroService.workSessionCount,
                    builder: (context, count, _) => Text(
                        l10n.pomodoroCyclesCompleted(count),
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.outline,
                            fontVariations: [const FontVariation('XTRA', 600)])),
                  ),
                  const SizedBox(height: 8), // Отступ
                  Text(l10n.pomodoroNextCycle(pomodoroService.nextSessionTitle),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontVariations: [const FontVariation('XTRA', 550)])),
                ],
              );

              return OrientationBuilder(builder: (context, orientation) {
                if (orientation == Orientation.portrait) {
                  // --- ПОРТРЕТНАЯ ОРИЕНТАЦИЯ ---
                  return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          titleWidget,
                          const SizedBox(height: 40),
                          timerWidget,
                          const SizedBox(height: 60),
                          Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SpringyButtonWrapper(
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                          end: pomodoroService.currentSession.value ==
                                  PomodoroSession.work
                              ? theme.colorScheme.primary
                              : pomodoroService.currentSession.value ==
                                      PomodoroSession.shortBreak
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.tertiary),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, color, child) {
                        return ElevatedButton(
                          onPressed: isRunning
                              ? pomodoroService.pauseTimer
                              : pomodoroService.startTimer,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            minimumSize: const Size(150, 100),
                            backgroundColor: color,
                          ),
                          child: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                            size: 56,
                            color: pomodoroService.currentSession.value ==
                                    PomodoroSession.work
                                ? theme.colorScheme.onPrimary
                                : pomodoroService.currentSession.value ==
                                        PomodoroSession.shortBreak
                                    ? theme.colorScheme.onSecondary
                                    : theme.colorScheme.onTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Кнопка сброса
                  _SpringyButtonWrapper(
                    child: buildTonalButton(
                        theme, Icons.refresh, pomodoroService.resetTimer, const Size(75, 100)),
                  ),
                  const SizedBox(width: 4),
                  // Кнопка "следующий"
                  _SpringyButtonWrapper(
                    child: buildTonalButton(theme, Icons.skip_next,
                        pomodoroService.moveToNextSession, const Size(50, 100)),
                  ),
                ],
              ),
                          const SizedBox(height: 20),
                          infoPanel,
                          const SizedBox(
                              height: 100), // Отступ до плавающей кнопки
                        ],
                    ),
                  );
                } else {
                  // --- ГОРИЗОНТАЛЬНАЯ ОРИЕНТАЦИЯ ---
                  return Row(
                    children: [
                      // Левая часть: Таймер и информация
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [timerWidget],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [titleWidget, const SizedBox(height: 20), infoPanel],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Правая часть: Кнопки управления
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SpringyButtonWrapper(
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                          end: pomodoroService.currentSession.value ==
                                  PomodoroSession.work
                              ? theme.colorScheme.primary
                              : pomodoroService.currentSession.value ==
                                      PomodoroSession.shortBreak
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.tertiary),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, color, child) {
                        return ElevatedButton(
                          onPressed: isRunning
                              ? pomodoroService.pauseTimer
                              : pomodoroService.startTimer,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            minimumSize: const Size(100, 150),
                            backgroundColor: color,
                          ),
                          child: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                            size: 56,
                            color: pomodoroService.currentSession.value ==
                                    PomodoroSession.work
                                ? theme.colorScheme.onPrimary
                                : pomodoroService.currentSession.value ==
                                        PomodoroSession.shortBreak
                                    ? theme.colorScheme.onSecondary
                                    : theme.colorScheme.onTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Кнопка сброса
                  _SpringyButtonWrapper(
                    child: buildTonalButton(
                        theme, Icons.refresh, pomodoroService.resetTimer, const Size(100, 75)),
                  ),
                  const SizedBox(height: 4),
                  // Кнопка "следующий"
                  _SpringyButtonWrapper(
                    child: buildTonalButton(theme, Icons.skip_next,
                        pomodoroService.moveToNextSession, const Size(100, 50)),
                  ),
                ],
              ),
                      ),
                    ],
                  );
                }
              });
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<PomodoroSession>(
        valueListenable: pomodoroService.currentSession,
        builder: (context, session, _) {
          return TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                  end: session == PomodoroSession.work
                      ? theme.colorScheme.primaryContainer
                      : session == PomodoroSession.shortBreak
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.tertiaryContainer),
              duration: const Duration(milliseconds: 250),
              builder: (context, color, child) {
                return FloatingActionButton.extended(
                  heroTag: 'pomodoro-fab', // Уникальный тег для кнопки
                  onPressed: () => _showSettingsDialog(context),
                  label: Text(l10n.configure),
                  icon: const Icon(Icons.settings_outlined),
                  backgroundColor: color,
                  foregroundColor: pomodoroService.currentSession.value == PomodoroSession.work 
                    ? theme.colorScheme.primary 
                    : pomodoroService.currentSession.value == PomodoroSession.shortBreak 
                      ? theme.colorScheme.secondary 
                      : theme.colorScheme.tertiary,
                );
              });
        },
      ), 
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 1. Создаем контроллеры здесь, инициализируя их текущими значениями
        final workController = TextEditingController(
            text: settingsService.pomodoroWorkDurationNotifier.value.toString());
        final shortBreakController = TextEditingController(
            text: settingsService.pomodoroShortBreakDurationNotifier.value.toString());
        final longBreakController = TextEditingController(
            text: settingsService.pomodoroLongBreakDurationNotifier.value.toString());

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.pomodoroIntervalSettings),
          content: _buildPomodoroSettings(
              workController, shortBreakController, longBreakController),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.reset),
              onPressed: () {
                settingsService.setPomodoroWorkDuration(25);
                settingsService.setPomodoroShortBreakDuration(5);
                settingsService.setPomodoroLongBreakDuration(15);
              }
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.save),
              onPressed: () {
                // 2. При нажатии "Close" считываем значения и сохраняем
                final workValue = int.tryParse(workController.text);
                if (workValue != null) settingsService.setPomodoroWorkDuration(workValue);
                final shortBreakValue = int.tryParse(shortBreakController.text);
                if (shortBreakValue != null) settingsService.setPomodoroShortBreakDuration(shortBreakValue);
                final longBreakValue = int.tryParse(longBreakController.text);
                if (longBreakValue != null) settingsService.setPomodoroLongBreakDuration(longBreakValue);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

  }

  Widget buildTonalButton(ThemeData theme, IconData icon, VoidCallback onPressed, Size minimumSize) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
          end: pomodoroService.currentSession.value == PomodoroSession.work
              ? theme.colorScheme.primaryContainer
              : pomodoroService.currentSession.value == PomodoroSession.shortBreak
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.tertiaryContainer),
      duration: const Duration(milliseconds: 250),
      builder: (context, color, child) {
        return IconButton.filledTonal(
          iconSize: 40,
          onPressed: onPressed,
          icon: Icon(icon),
          color: pomodoroService.currentSession.value == PomodoroSession.work
              ? theme.colorScheme.primary
              : pomodoroService.currentSession.value == PomodoroSession.shortBreak
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.tertiary,
          style: IconButton.styleFrom(minimumSize: minimumSize, backgroundColor: color),
        );
      },
    );
  }
}

/// Виджет-обертка для создания "пружинистого" эффекта при нажатии.
class _SpringyButtonWrapper extends StatefulWidget {
  final Widget child;
  const _SpringyButtonWrapper({required this.child});

  @override
  State<_SpringyButtonWrapper> createState() => _SpringyButtonWrapperState();
}

class _SpringyButtonWrapperState extends State<_SpringyButtonWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

Widget _buildInputColumn(
    {required String label,
    required ValueNotifier<int> durationNotifier,
    required ValueChanged<int> onSave,
    bool isFirst = false,
    bool isLast = false, 
    required BuildContext context,
    required TextEditingController controller}) { // Добавлен context
  final theme = Theme.of(context);
  
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            // color: theme.colorScheme.outline,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 100, // Высота поля ввода
          width: 100,
          decoration: BoxDecoration(
            color: pomodoroService.currentSession.value == PomodoroSession.work
              ? theme.colorScheme.primaryContainer
              : pomodoroService.currentSession.value == PomodoroSession.shortBreak
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.tertiaryContainer, // Цвет самого инпута
            // Закругляем только внешние края блока
            borderRadius: BorderRadius.only(
              topLeft: isFirst ? Radius.circular(25) : Radius.circular(5),
              bottomLeft: isFirst ? Radius.circular(25) : Radius.circular(5),
              topRight: isLast ? Radius.circular(25) : Radius.circular(5),
              bottomRight: isLast ? Radius.circular(25) : Radius.circular(5),
            ),
            // Добавляем тонкую разделительную линию справа для первых двух блоков
            border: !isLast
                ? Border(right: BorderSide(color: theme.colorScheme.surfaceContainerHigh, width: 2))
                : null,
          ),
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: durationNotifier,
              builder: (context, value, child) {
                // Обновляем контроллер, если значение изменилось извне
                if (controller.text != value.toString()) {
                  controller.text = value.toString();
                }
                return TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (text) {
                    final intValue = int.tryParse(text);
                    if (intValue != null) {
                      onSave(intValue);
                    }
                  },
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: pomodoroService.currentSession.value == PomodoroSession.work
                      ? theme.colorScheme.onPrimaryContainer
                      : pomodoroService.currentSession.value == PomodoroSession.shortBreak
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none, // Убираем стандартную рамку
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

// Хелпер для настроек Pomodoro
Widget _buildPomodoroSettings(
    TextEditingController workController,
    TextEditingController shortBreakController,
    TextEditingController longBreakController) {
  return Builder(builder: (context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildInputColumn(
          label: l10n.pomodoroWorkCycle,
          controller: workController,
          durationNotifier: settingsService.pomodoroWorkDurationNotifier,
          onSave: settingsService.setPomodoroWorkDuration,
          context: context,
          isFirst: true,
        ),
        _buildInputColumn(
          label: l10n.pomodoroShortBreak,
          controller: shortBreakController,
          durationNotifier: settingsService.pomodoroShortBreakDurationNotifier,
          onSave: settingsService.setPomodoroShortBreakDuration,
          context: context,
        ),
        _buildInputColumn(
          label: l10n.pomodoroLongBreak,
          controller: longBreakController,
          durationNotifier: settingsService.pomodoroLongBreakDurationNotifier,
          onSave: settingsService.setPomodoroLongBreakDuration,
          isLast: true,
          context: context,
        ),
      ],
    );
  });
}
