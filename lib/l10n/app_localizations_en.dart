// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myASIEC => 'MyASIEC';

  @override
  String get confirm => 'Confirmation';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get empty => 'Empty';

  @override
  String get error => 'Error';

  @override
  String get search => 'Search';

  @override
  String get filters => 'Filters';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get configure => 'Configure';

  @override
  String get reset => 'Reset';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get pause => 'Pause';

  @override
  String get minute => 'min.';

  @override
  String get scheduleScreen => 'Schedule';

  @override
  String get taskScreen => 'Tasks';

  @override
  String get handbookScreen => 'Handbook';

  @override
  String get moreScreen => 'More';

  @override
  String get group => 'Group';

  @override
  String get teacher => 'Teacher';

  @override
  String get room => 'Room';

  @override
  String get scheduleShortBreak => 'Short Break';

  @override
  String get scheduleLongBreak => 'Long Break';

  @override
  String get scheduleWindow => 'Window';

  @override
  String get taskEmpty => 'There is no tasks';

  @override
  String get taskCreate => 'Add task';

  @override
  String get taskEdit => 'Edit task';

  @override
  String get taskSubject => 'Subject';

  @override
  String get taskSubgroup => 'Subgroup';

  @override
  String get taskTask => 'Task';

  @override
  String get taskDueDate => 'Due date';

  @override
  String get taskPhoto => 'Photo';

  @override
  String get taskSaveLocally => 'Save locally';

  @override
  String get taskSaveChanges => 'Save changes';

  @override
  String get taskDeleteConfirmation =>
      'Are you sure you want to delete this task?';

  @override
  String get handbookCreate => 'Add formula';

  @override
  String get handbookEdit => 'Edit formula';

  @override
  String get handbookEnterName => 'Enter name';

  @override
  String get handbookFormula => 'Formula';

  @override
  String get handbookOpenLatexEditor => 'Open LaTeX editor';

  @override
  String get handbookLatexEditor => 'LaTeX editor';

  @override
  String get handbookLatexHint => 'Enter LaTeX here...';

  @override
  String get handbookSummary => 'Short description';

  @override
  String get handbookDescription => 'Description';

  @override
  String get handbookPhotoURL => 'Photo URL';

  @override
  String get handbookTags => 'Tags (separated by commas)';

  @override
  String get pomodoroTimer => 'Pomodoro timer';

  @override
  String get pomodoroIntervalSettings => 'Interval settings';

  @override
  String get pomodoroWorkCycle => 'Focus';

  @override
  String get pomodoroShortBreak => 'Short break';

  @override
  String get pomodoroLongBreak => 'Long break';

  @override
  String pomodoroWorkCyclesCompleted(int count) {
    return 'Focus cycles completed: $count';
  }

  @override
  String pomodoroCyclesCompleted(int count) {
    return 'Cycles completed: $count';
  }

  @override
  String pomodoroNextCycle(String nextSessionTitle) {
    return 'Next cycle: $nextSessionTitle';
  }

  @override
  String get notificationTimeOut =>
      'Time out! Start next cycle in 5 seconds...';

  @override
  String get hallOfFame => 'Hall of fame';

  @override
  String get hallOfFameTip =>
      'Here are people who supported the development of the application';

  @override
  String get settings => 'Settings';

  @override
  String get settingSystem => 'System';

  @override
  String get settingNotSelected => 'Not selected';

  @override
  String get settingShowBreaks => 'Show breaks';

  @override
  String get settingAppearance => 'Appearance';

  @override
  String get settingTheme => 'Theme';

  @override
  String get settingThemeLight => 'Light';

  @override
  String get settingThemeDark => 'Dark';

  @override
  String get settingThemeMaterialYou => 'Material You colors';

  @override
  String get settingThemeMaterialYouDescription =>
      'Use Material You colors (Android 12+)';

  @override
  String get settingIcons => 'App Icon';

  @override
  String get iconDefault => 'Default';

  @override
  String get iconFlow => 'Flow';

  @override
  String get iconPurple => 'Purple';

  @override
  String get iconLegacy => 'Legacy';

  @override
  String get iconLegacyAlt => 'Legacy Alt';

  @override
  String get iconBarracuda => 'Barracuda';

  @override
  String get settingLanguage => 'Language';

  @override
  String get telegramChannelLink => 'Official Telegram channel';

  @override
  String get aboutApp => 'About app';

  @override
  String get aboutDescription =>
      'Author: Popkov Dmitriy (9ОИБ231)\nIdea: Nikiforov Maxim (11ОИБ232)\nMade with ❤️ in Flutter';

  @override
  String get appIconChangedSuccessfully => 'Icon changed successfully';

  @override
  String get appIconChangeFailed => 'Icon change failed';
}
