import 'dart:async';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'package:home_widget/home_widget.dart';
import '../l10n/app_localizations.dart';


enum PomodoroSession { work, shortBreak, longBreak }

class PomodoroService {
  // --- Singleton Pattern ---
  static final PomodoroService _instance = PomodoroService._internal();
  factory PomodoroService() {
    return _instance;
  }
  PomodoroService._internal();

  // --- Dependencies ---
  final NotificationService _notificationService = NotificationService();
  AppLocalizations? _l10n;


  // --- State Notifiers (чтобы UI мог слушать изменения) ---
  final ValueNotifier<int> remainingTime = ValueNotifier(0);
  final ValueNotifier<bool> isTimerRunning = ValueNotifier(false);
  final ValueNotifier<PomodoroSession> currentSession = ValueNotifier(PomodoroSession.work);
  final ValueNotifier<int> workSessionCount = ValueNotifier(0);
  final ValueNotifier<int> fullSessionCount = ValueNotifier(0);

  // --- Private State ---
  Timer? _timer;
  late int _workDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  static const int _sessionsBeforeLongBreak = 4;

  // --- Initialization ---
  void init() {
    _loadDurationsFromSettings();
    remainingTime.value = _workDuration;
    _updateHomeWidget(); // Обновляем виджет при инициализации

    // Слушаем изменения в настройках
    settingsService.pomodoroWorkDurationNotifier.addListener(_onSettingsChanged);
    settingsService.pomodoroShortBreakDurationNotifier.addListener(_onSettingsChanged);
    settingsService.pomodoroLongBreakDurationNotifier.addListener(_onSettingsChanged);
  }

  void dispose() {
    _timer?.cancel();
    settingsService.pomodoroWorkDurationNotifier.removeListener(_onSettingsChanged);
    settingsService.pomodoroShortBreakDurationNotifier.removeListener(_onSettingsChanged);
    settingsService.pomodoroLongBreakDurationNotifier.removeListener(_onSettingsChanged);
  }

  // --- Метод для установки локализации из UI ---
  void setLocalizations(AppLocalizations l10n) {
    _l10n = l10n;
  }

  // --- Getters for computed properties ---
  String get sessionTitle {
    if (_l10n == null) return 'Work'; // Fallback
    switch (currentSession.value) {
      case PomodoroSession.work:
        return _l10n!.pomodoroWorkCycle;
      case PomodoroSession.shortBreak:
        return _l10n!.pomodoroShortBreak;
      case PomodoroSession.longBreak:
        return _l10n!.pomodoroLongBreak;
    }
  }

  int get currentDuration {
    switch (currentSession.value) {
      case PomodoroSession.work:
        return _workDuration;
      case PomodoroSession.shortBreak:
        return _shortBreakDuration;
      case PomodoroSession.longBreak:
        return _longBreakDuration;
    }
  }

  // --- Public Methods (API for the UI) ---
  void startTimer() {
    if (isTimerRunning.value) return;
    isTimerRunning.value = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.value > 0) {
        remainingTime.value--;
        _updateNotification();
        _updateHomeWidget(); // Обновляем виджет каждую секунду
      } else {
        _timer?.cancel();
        isTimerRunning.value = false; // Останавливаем таймер
        final notificationBody = _l10n!.notificationTimeOut;
        _notificationService.showCompletionNotification(sessionTitle, notificationBody);
        
        // Ждем 5 секунд, чтобы звук уведомления успел проиграться
        Future.delayed(const Duration(seconds: 5), () {
          // Запускаем следующую сессию только если пользователь не сделал ничего другого
          if (!isTimerRunning.value) moveToNextSession();
        });
      }
    });
  }

  void pauseTimer() {
    if (!isTimerRunning.value) return;
    _timer?.cancel();
    isTimerRunning.value = false;
    _notificationService.cancelAllNotifications();
    _updateHomeWidget();
  }

  void resetTimer() {
    _timer?.cancel();
    isTimerRunning.value = false;
    remainingTime.value = currentDuration;
    _notificationService.cancelAllNotifications();
    _updateHomeWidget();
  }
  void resetAll() {
    _timer?.cancel();
    isTimerRunning.value = false;
    remainingTime.value = settingsService.pomodoroWorkDurationNotifier.value * 60;
    _notificationService.cancelAllNotifications();
    workSessionCount.value = 0;
    fullSessionCount.value = 0;
    currentSession.value = PomodoroSession.work;
    _updateHomeWidget();

  }

  void moveToNextSession() {
    _timer?.cancel();
    if (currentSession.value == PomodoroSession.work) {
      workSessionCount.value++;
      if (workSessionCount.value % _sessionsBeforeLongBreak == 0) {
        currentSession.value = PomodoroSession.longBreak;
        // fullSessionCount.value++;
      } else {
        currentSession.value = PomodoroSession.shortBreak;
      }
    } else {
      if (currentSession.value == PomodoroSession.longBreak) {
        fullSessionCount.value++;
      }
      currentSession.value = PomodoroSession.work;
    }

    isTimerRunning.value = false;
    remainingTime.value = currentDuration;

    _updateHomeWidget();
    // Автоматически запускаем следующую сессию
    startTimer();
  }
  // --- Метод для предсказания следующей сессии ---
  String get nextSessionTitle {
    if (_l10n == null) return 'Break'; // Fallback
    if (currentSession.value == PomodoroSession.work) {
      if ((workSessionCount.value + 1) % _sessionsBeforeLongBreak == 0) {
        return _l10n!.pomodoroLongBreak;
      } else {
        return _l10n!.pomodoroShortBreak;
      }
    } else {
      return _l10n!.pomodoroWorkCycle;
    }
  }
  // --- Private Helpers ---
  void _loadDurationsFromSettings() {
    _workDuration = settingsService.pomodoroWorkDurationNotifier.value * 60;
    _shortBreakDuration = settingsService.pomodoroShortBreakDurationNotifier.value * 60;
    _longBreakDuration = settingsService.pomodoroLongBreakDurationNotifier.value * 60;
  }

  void _onSettingsChanged() {
    _loadDurationsFromSettings();
    if (!isTimerRunning.value) {
      resetTimer();
    }
  }

  void _updateNotification() {
    if (!isTimerRunning.value) return;
    _notificationService.showProgressNotification(
      sessionTitle,
      formatTime(remainingTime.value),
      currentDuration,
      currentDuration - remainingTime.value,
    );
  }

  String formatTime(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // --- Метод для обновления виджета ---
  Future<void> _updateHomeWidget() async {
    await HomeWidget.saveWidgetData<String>('session_title', sessionTitle);
    await HomeWidget.saveWidgetData<String>('time', formatTime(remainingTime.value));
    await HomeWidget.saveWidgetData<String>(
        'status', isTimerRunning.value && currentSession.value == PomodoroSession.work 
          ? '${_l10n?.pomodoroWorkCycle}...' 
          : isTimerRunning.value && currentSession.value == PomodoroSession.shortBreak 
            ? '${_l10n?.pomodoroShortBreak}...'
            : isTimerRunning.value && currentSession.value == PomodoroSession.longBreak 
              ? '${_l10n?.pomodoroLongBreak}...'
              : '${_l10n?.pause}...');
    await HomeWidget.updateWidget(
      // Имя класса нашего провайдера
      name: 'PomodoroWidgetProvider',
      androidName: 'PomodoroWidgetProvider',
    );
  }
}

// --- Global instance (Singleton) ---
final pomodoroService = PomodoroService();

// Вспомогательный класс для доступа к контексту, если он нужен вне виджетов
// Это может быть полезно для сервисов, которые не имеют прямого доступа к BuildContext
class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}