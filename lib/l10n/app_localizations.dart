import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @myASIEC.
  ///
  /// In ru, this message translates to:
  /// **'МойАПЭК'**
  String get myASIEC;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @empty.
  ///
  /// In ru, this message translates to:
  /// **'Пусто'**
  String get empty;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @filters.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get filters;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @optional.
  ///
  /// In ru, this message translates to:
  /// **'Опционально'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно'**
  String get required;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get edit;

  /// No description provided for @configure.
  ///
  /// In ru, this message translates to:
  /// **'Настроить'**
  String get configure;

  /// No description provided for @reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get reset;

  /// No description provided for @nothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get nothingFound;

  /// No description provided for @pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get pause;

  /// No description provided for @minute.
  ///
  /// In ru, this message translates to:
  /// **'мин.'**
  String get minute;

  /// No description provided for @scheduleScreen.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get scheduleScreen;

  /// No description provided for @taskScreen.
  ///
  /// In ru, this message translates to:
  /// **'Задания'**
  String get taskScreen;

  /// No description provided for @handbookScreen.
  ///
  /// In ru, this message translates to:
  /// **'Справочник'**
  String get handbookScreen;

  /// No description provided for @moreScreen.
  ///
  /// In ru, this message translates to:
  /// **'Больше'**
  String get moreScreen;

  /// No description provided for @group.
  ///
  /// In ru, this message translates to:
  /// **'Группа'**
  String get group;

  /// No description provided for @teacher.
  ///
  /// In ru, this message translates to:
  /// **'Препод.'**
  String get teacher;

  /// No description provided for @room.
  ///
  /// In ru, this message translates to:
  /// **'Ауд.'**
  String get room;

  /// No description provided for @scheduleShortBreak.
  ///
  /// In ru, this message translates to:
  /// **'Короткий перерыв'**
  String get scheduleShortBreak;

  /// No description provided for @scheduleLongBreak.
  ///
  /// In ru, this message translates to:
  /// **'Длинный перерыв'**
  String get scheduleLongBreak;

  /// No description provided for @scheduleWindow.
  ///
  /// In ru, this message translates to:
  /// **'Окно'**
  String get scheduleWindow;

  /// No description provided for @taskEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Заданий нет'**
  String get taskEmpty;

  /// No description provided for @taskCreate.
  ///
  /// In ru, this message translates to:
  /// **'Добавить задание'**
  String get taskCreate;

  /// No description provided for @taskEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать задание'**
  String get taskEdit;

  /// No description provided for @taskSubject.
  ///
  /// In ru, this message translates to:
  /// **'Предмет'**
  String get taskSubject;

  /// No description provided for @taskSubgroup.
  ///
  /// In ru, this message translates to:
  /// **'Подгруппа'**
  String get taskSubgroup;

  /// No description provided for @taskTask.
  ///
  /// In ru, this message translates to:
  /// **'Задание'**
  String get taskTask;

  /// No description provided for @taskDueDate.
  ///
  /// In ru, this message translates to:
  /// **'Срок сдачи'**
  String get taskDueDate;

  /// No description provided for @taskPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get taskPhoto;

  /// No description provided for @taskSaveLocally.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить локально'**
  String get taskSaveLocally;

  /// No description provided for @taskSaveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get taskSaveChanges;

  /// No description provided for @taskDeleteConfirmation.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить задание?'**
  String get taskDeleteConfirmation;

  /// No description provided for @handbookCreate.
  ///
  /// In ru, this message translates to:
  /// **'Добавить формулу'**
  String get handbookCreate;

  /// No description provided for @handbookEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать формулу'**
  String get handbookEdit;

  /// No description provided for @handbookEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get handbookEnterName;

  /// No description provided for @handbookFormula.
  ///
  /// In ru, this message translates to:
  /// **'Формула'**
  String get handbookFormula;

  /// No description provided for @handbookOpenLatexEditor.
  ///
  /// In ru, this message translates to:
  /// **'Открыть редактор формул'**
  String get handbookOpenLatexEditor;

  /// No description provided for @handbookLatexEditor.
  ///
  /// In ru, this message translates to:
  /// **'Редактор формул LaTeX'**
  String get handbookLatexEditor;

  /// No description provided for @handbookLatexHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите LaTeX здесь...'**
  String get handbookLatexHint;

  /// No description provided for @handbookSummary.
  ///
  /// In ru, this message translates to:
  /// **'Краткое описание'**
  String get handbookSummary;

  /// No description provided for @handbookDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get handbookDescription;

  /// No description provided for @handbookPhotoURL.
  ///
  /// In ru, this message translates to:
  /// **'URL изображения'**
  String get handbookPhotoURL;

  /// No description provided for @handbookTags.
  ///
  /// In ru, this message translates to:
  /// **'Теги (через запятую)'**
  String get handbookTags;

  /// No description provided for @pomodoroTimer.
  ///
  /// In ru, this message translates to:
  /// **'Pomodoro Таймер'**
  String get pomodoroTimer;

  /// No description provided for @pomodoroIntervalSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки интервалов'**
  String get pomodoroIntervalSettings;

  /// No description provided for @pomodoroWorkCycle.
  ///
  /// In ru, this message translates to:
  /// **'Фокус'**
  String get pomodoroWorkCycle;

  /// No description provided for @pomodoroShortBreak.
  ///
  /// In ru, this message translates to:
  /// **'Короткий отдых'**
  String get pomodoroShortBreak;

  /// No description provided for @pomodoroLongBreak.
  ///
  /// In ru, this message translates to:
  /// **'Длинный отдых'**
  String get pomodoroLongBreak;

  /// Показывает количество завершенных фокусировок Pomodoro
  ///
  /// In ru, this message translates to:
  /// **'Фокусировок завершено: {count}'**
  String pomodoroWorkCyclesCompleted(int count);

  /// Показывает количество завершенных циклов Pomodoro (4 фокусировки)
  ///
  /// In ru, this message translates to:
  /// **'Циклов завершено: {count}'**
  String pomodoroCyclesCompleted(int count);

  /// No description provided for @pomodoroNextCycle.
  ///
  /// In ru, this message translates to:
  /// **'Следующий цикл: {nextSessionTitle}'**
  String pomodoroNextCycle(String nextSessionTitle);

  /// No description provided for @notificationTimeOut.
  ///
  /// In ru, this message translates to:
  /// **'Время вышло! Запуск следующего цикла через 5 секунд...'**
  String get notificationTimeOut;

  /// No description provided for @hallOfFame.
  ///
  /// In ru, this message translates to:
  /// **'Зал славы'**
  String get hallOfFame;

  /// Подсказка как попасть в зал славы в нижней части экрана
  ///
  /// In ru, this message translates to:
  /// **'Здесь находятся люди, поддержавшие разработку приложения'**
  String get hallOfFameTip;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @settingSystem.
  ///
  /// In ru, this message translates to:
  /// **'Система'**
  String get settingSystem;

  /// No description provided for @settingNotSelected.
  ///
  /// In ru, this message translates to:
  /// **'Не выбрано'**
  String get settingNotSelected;

  /// No description provided for @settingShowBreaks.
  ///
  /// In ru, this message translates to:
  /// **'Показывать перерывы'**
  String get settingShowBreaks;

  /// No description provided for @settingAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingAppearance;

  /// No description provided for @settingTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingTheme;

  /// No description provided for @settingThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get settingThemeLight;

  /// No description provided for @settingThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get settingThemeDark;

  /// No description provided for @settingThemeMaterialYou.
  ///
  /// In ru, this message translates to:
  /// **'Динамическое оформление'**
  String get settingThemeMaterialYou;

  /// No description provided for @settingThemeMaterialYouDescription.
  ///
  /// In ru, this message translates to:
  /// **'Использовать цвета обоев (Android 12+)'**
  String get settingThemeMaterialYouDescription;

  /// No description provided for @settingIcons.
  ///
  /// In ru, this message translates to:
  /// **'Иконка приложения'**
  String get settingIcons;

  /// No description provided for @iconDefault.
  ///
  /// In ru, this message translates to:
  /// **'Обычная'**
  String get iconDefault;

  /// No description provided for @iconFlow.
  ///
  /// In ru, this message translates to:
  /// **'Поток'**
  String get iconFlow;

  /// No description provided for @iconPurple.
  ///
  /// In ru, this message translates to:
  /// **'Фиолетовый'**
  String get iconPurple;

  /// No description provided for @iconLegacy.
  ///
  /// In ru, this message translates to:
  /// **'Наследие'**
  String get iconLegacy;

  /// No description provided for @iconLegacyAlt.
  ///
  /// In ru, this message translates to:
  /// **'Наследие Alt'**
  String get iconLegacyAlt;

  /// No description provided for @iconBarracuda.
  ///
  /// In ru, this message translates to:
  /// **'Барракуда'**
  String get iconBarracuda;

  /// No description provided for @settingLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingLanguage;

  /// No description provided for @telegramChannelLink.
  ///
  /// In ru, this message translates to:
  /// **'Официальный Telegram канал'**
  String get telegramChannelLink;

  /// No description provided for @aboutApp.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get aboutApp;

  /// No description provided for @aboutDescription.
  ///
  /// In ru, this message translates to:
  /// **'Автор: Попков Дмитрий (9ОИБ231)\nИдея: Никифоров Максим (11ОИБ232)\nСделано с ❤️ в Flutter'**
  String get aboutDescription;

  /// No description provided for @appIconChangedSuccessfully.
  ///
  /// In ru, this message translates to:
  /// **'Иконка изменена успешно'**
  String get appIconChangedSuccessfully;

  /// No description provided for @appIconChangeFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить иконку'**
  String get appIconChangeFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
