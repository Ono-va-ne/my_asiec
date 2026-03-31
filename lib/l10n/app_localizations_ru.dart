// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get myASIEC => 'МойАПЭК';

  @override
  String get confirm => 'Подтверждение';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get close => 'Закрыть';

  @override
  String get empty => 'Пусто';

  @override
  String get error => 'Ошибка';

  @override
  String get search => 'Поиск';

  @override
  String get filters => 'Фильтры';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get optional => 'Опционально';

  @override
  String get required => 'Обязательно';

  @override
  String get add => 'Добавить';

  @override
  String get edit => 'Редактировать';

  @override
  String get configure => 'Настроить';

  @override
  String get reset => 'Сбросить';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get pause => 'Пауза';

  @override
  String get minute => 'мин.';

  @override
  String get scheduleScreen => 'Расписание';

  @override
  String get taskScreen => 'Задания';

  @override
  String get handbookScreen => 'Справочник';

  @override
  String get moreScreen => 'Больше';

  @override
  String get group => 'Группа';

  @override
  String get teacher => 'Препод.';

  @override
  String get room => 'Ауд.';

  @override
  String get scheduleShortBreak => 'Короткий перерыв';

  @override
  String get scheduleLongBreak => 'Длинный перерыв';

  @override
  String get scheduleWindow => 'Окно';

  @override
  String get taskEmpty => 'Заданий нет';

  @override
  String get taskCreate => 'Добавить задание';

  @override
  String get taskEdit => 'Редактировать задание';

  @override
  String get taskSubject => 'Предмет';

  @override
  String get taskSubgroup => 'Подгруппа';

  @override
  String get taskTask => 'Задание';

  @override
  String get taskDueDate => 'Срок сдачи';

  @override
  String get taskPhoto => 'Фото';

  @override
  String get taskSaveLocally => 'Сохранить локально';

  @override
  String get taskSaveChanges => 'Сохранить изменения';

  @override
  String get taskDeleteConfirmation =>
      'Вы уверены, что хотите удалить задание?';

  @override
  String get handbookCreate => 'Добавить формулу';

  @override
  String get handbookEdit => 'Редактировать формулу';

  @override
  String get handbookEnterName => 'Введите название';

  @override
  String get handbookFormula => 'Формула';

  @override
  String get handbookOpenLatexEditor => 'Открыть редактор формул';

  @override
  String get handbookLatexEditor => 'Редактор формул LaTeX';

  @override
  String get handbookLatexHint => 'Введите LaTeX здесь...';

  @override
  String get handbookSummary => 'Краткое описание';

  @override
  String get handbookDescription => 'Описание';

  @override
  String get handbookPhotoURL => 'URL изображения';

  @override
  String get handbookTags => 'Теги (через запятую)';

  @override
  String get pomodoroTimer => 'Pomodoro Таймер';

  @override
  String get pomodoroIntervalSettings => 'Настройки интервалов';

  @override
  String get pomodoroWorkCycle => 'Фокус';

  @override
  String get pomodoroShortBreak => 'Короткий отдых';

  @override
  String get pomodoroLongBreak => 'Длинный отдых';

  @override
  String pomodoroWorkCyclesCompleted(int count) {
    return 'Фокусировок завершено: $count';
  }

  @override
  String pomodoroCyclesCompleted(int count) {
    return 'Циклов завершено: $count';
  }

  @override
  String pomodoroNextCycle(String nextSessionTitle) {
    return 'Следующий цикл: $nextSessionTitle';
  }

  @override
  String get notificationTimeOut =>
      'Время вышло! Запуск следующего цикла через 5 секунд...';

  @override
  String get hallOfFame => 'Зал славы';

  @override
  String get hallOfFameTip =>
      'Здесь находятся люди, поддержавшие разработку приложения';

  @override
  String get settings => 'Настройки';

  @override
  String get settingSystem => 'Система';

  @override
  String get settingNotSelected => 'Не выбрано';

  @override
  String get settingShowBreaks => 'Показывать перерывы';

  @override
  String get settingAppearance => 'Оформление';

  @override
  String get settingTheme => 'Тема';

  @override
  String get settingThemeLight => 'Светлая';

  @override
  String get settingThemeDark => 'Тёмная';

  @override
  String get settingThemeMaterialYou => 'Динамическое оформление';

  @override
  String get settingThemeMaterialYouDescription =>
      'Использовать цвета обоев (Android 12+)';

  @override
  String get settingIcons => 'Иконка приложения';

  @override
  String get iconDefault => 'Обычная';

  @override
  String get iconFlow => 'Поток';

  @override
  String get iconPurple => 'Фиолетовый';

  @override
  String get iconLegacy => 'Наследие';

  @override
  String get iconLegacyAlt => 'Наследие Alt';

  @override
  String get iconBarracuda => 'Барракуда';

  @override
  String get settingLanguage => 'Язык';

  @override
  String get telegramChannelLink => 'Официальный Telegram канал';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get aboutDescription =>
      'Автор: Попков Дмитрий (9ОИБ231)\nИдея: Никифоров Максим (11ОИБ232)\nСделано с ❤️ в Flutter';

  @override
  String get appIconChangedSuccessfully => 'Иконка изменена успешно';

  @override
  String get appIconChangeFailed => 'Не удалось изменить иконку';
}
