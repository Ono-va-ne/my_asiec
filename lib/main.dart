import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/schedule_screen.dart';
import '../pages/news_screen.dart';
import '../pages/settings_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import '../services/settings_service.dart';
import '../utils/logger_setup.dart';
// import 'package:http/http.dart' as http;


// Класс для обхода проверки SSL (ТОЛЬКО ДЛЯ РАЗРАБОТКИ!)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true; // Принимаем любой сертификат
  }
}

void main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // // --- Настройка логирования ---
    // // Создаем начальный логгер (может быть только консольный до получения пути)
    // // final initialLogger = Logger( /* ... только ConsoleOutput ... */);
    // // Инициализируем путь и реальный FileOutput (это асинхронно!)
    // await setupLogging(); // <-- ВЫЗЫВАЕМ НАСТРОЙКУ
    // // *** Важное изменение для обновления FileOutput ***
    // // Так как logger final, а FileOutput нужно было создать после получения пути,
    // // мы создадим новый Logger с нужной конфигурацией здесь.
    // // Предыдущий logger будет заменен этим.
    // final fileOutput = FileOutput(file: _logFile, overrideExisting: false);
    // final consoleOutput = kDebugMode ? ConsoleOutput() : null;
    // final multiOutput = MultiOutput([ if (consoleOutput != null) consoleOutput, fileOutput]);

    // // Обновляем глобальный логгер (это не лучший паттерн, но рабочий для простоты)
    // // Вместо этого можно передавать логгер через DI (GetIt, Provider)
    // // Logger( ... ); // Не можем переназначить final, но можем настроить стандартный
    // // Стандартный Logger не позволяет менять output и printer после создания.
    // // Поэтому лучше использовать кастомный логгер или передавать его.
    // // Но для простоты, будем использовать глобальный logger, инициализированный в logger_setup.dart,
    // // осознавая, что FileOutput начнет работать только ПОСЛЕ setupLogging().
    // // Логи до этого момента попадут только в консоль (если включено).

    // // --- Настройка глобальных обработчиков ошибок ---
    // FlutterError.onError = recordFlutterError; // Для ошибок Flutter
    // PlatformDispatcher.instance.onError = (error, stack) { // Для ошибок Dart
    //   recordError(error, stack);
    //   return true; // Сообщаем, что ошибка обработана
    // };

    // logger.i("Запуск приложения..."); // Первый лог после настройки
    // Применяем обход проверки SSL глобально
    HttpOverrides.global = MyHttpOverrides(); // <-- ДОБАВЬ ЭТУ СТРОКУ

    // Инициализация локали (если используешь intl)
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ru_RU', null);

    WidgetsFlutterBinding.ensureInitialized(); // Убедимся, что есть перед loadSettings
    await settingsService.loadSettings();
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true); // Включаем кэширование Firestore
    runApp(MyApp()); // Запускаем твое приложение
  }, (error, stackTrace) {
    recordError(error, stackTrace);
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Обновленный хелпер для создания ThemeData
  ThemeData _createThemeData(Brightness brightness, Color? accentColor, ColorScheme? dynamicColors) {
     final baseColorScheme = dynamicColors ?? ColorScheme.fromSeed(
         seedColor: accentColor ?? Colors.blue,
         brightness: brightness
     );
     // Определяем цвета на основе яркости
     final scaffoldBackgroundColor = brightness == Brightness.light
         ? Colors.grey[100] // Светло-серый для светлой темы
         : Color(0xFF121212); // Стандартный темный фон Material
     final cardBackgroundColor = brightness == Brightness.light
         ? Colors.white
         : Colors.grey[850]; // Темно-серый для карт в темной теме
     final appBarBackgroundColor = brightness == Brightness.light
         ? baseColorScheme.surface // Или baseColorScheme.surface
         : baseColorScheme.surface; // Или baseColorScheme.surface

     return ThemeData(
        colorScheme: baseColorScheme,
        useMaterial3: true,
        brightness: brightness,

        // --- ЯВНЫЕ ОПРЕДЕЛЕНИЯ ---
        scaffoldBackgroundColor: scaffoldBackgroundColor,

        cardTheme: CardTheme(
           elevation: 1.0, // Небольшая тень
           color: cardBackgroundColor, // Используем определенный цвет
           margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Стандартные отступы
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),

        appBarTheme: AppBarTheme(
           elevation: brightness == Brightness.light ? 1.0 : 0.0, // Тень для светлой, нет для темной
           backgroundColor: appBarBackgroundColor, // Используем определенный цвет
           foregroundColor: baseColorScheme.onSurface, // Цвет иконок и текста в AppBar
           titleTextStyle: TextStyle(
              color: baseColorScheme.onSurface,
              fontSize: 18, // Или 20
              fontWeight: FontWeight.w500,
           ),
        ),

        // Можно добавить другие темы: textTheme, listTileTheme, dropdownTheme и т.д.
        // Например:
        // textTheme: TextTheme(
        //    bodyMedium: TextStyle(color: baseColorScheme.onSurface),
        //    // ... другие стили текста
        // ),
        // listTileTheme: ListTileThemeData(
        //    iconColor: baseColorScheme.onSurfaceVariant,
        // )
     );
  }
    // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      // Слушаем все три нотификатора темы одновременно
      return ValueListenableBuilder<ThemeMode>(
          valueListenable: settingsService.themeModeNotifier,
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<Color?>(
                valueListenable: settingsService.accentColorNotifier,
                builder: (context, accentColor, _) {
                  return ValueListenableBuilder<bool>(
                      valueListenable: settingsService.materialYouNotifier,
                      builder: (context, isMaterialYouEnabled, _) {

                        return MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: 'Мой АПЭК',
                          theme: _createThemeData(Brightness.light, accentColor, isMaterialYouEnabled ? lightDynamic : null),
                          darkTheme: _createThemeData(Brightness.dark, accentColor, isMaterialYouEnabled ? darkDynamic : null),
                          themeMode: themeMode,
                          localizationsDelegates: [
                            GlobalMaterialLocalizations.delegate, // Локализация для Material виджетов
                            GlobalWidgetsLocalizations.delegate,  // Локализация для базовых виджетов (направление текста и т.д.)
                            GlobalCupertinoLocalizations.delegate, // Локализация для Cupertino (iOS) виджетов (иногда нужна и для Material)
                          ],
                          supportedLocales: [
                            const Locale('ru', 'RU'), // Русский язык
                            const Locale('en', ''),   // Английский язык (хорошо иметь как запасной)
                            // Можешь добавить другие языки, если нужно
                          ],
                          home: MainScreen(),
                        );
                      }); // End MaterialYou Builder
                }); // End AccentColor Builder
          }); // End ThemeMode Builder
    }); // End DynamicColorBuilder

    // return MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   title: "МойАПЭК lite",
    //   theme: ThemeData(
    //     fontFamily: 'JetBrains Mono'),
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate, // Локализация для Material виджетов
      //   GlobalWidgetsLocalizations.delegate,  // Локализация для базовых виджетов (направление текста и т.д.)
      //   GlobalCupertinoLocalizations.delegate, // Локализация для Cupertino (iOS) виджетов (иногда нужна и для Material)
      // ],
      // supportedLocales: [
      //   const Locale('ru', 'RU'), // Русский язык
      //   const Locale('en', ''),   // Английский язык (хорошо иметь как запасной)
      //   // Можешь добавить другие языки, если нужно
      // ],
    //   home: MainScreen(),
    // );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Индекс выбранной вкладки (0 - Расписание, 1 - Новости)

  // Список виджетов-экранов для отображения
  static const List<Widget> _widgetOptions = <Widget>[
    ScheduleScreen(), // Твой существующий экран расписания
    NewsScreen(),
    SettingsScreen(),     // Новый экран новостей
  ];

  // Метод для смены вкладки
void _onItemTapped(int index) {
    // --- Проверяем, нажал ли пользователь на вкладку "Новости" (индекс 1) ---
    if (index == 1) { // 0 - Расписание, 1 - Новости, 2 - Настройки
      // Показываем диалоговое окно
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row( // Добавим иконку для красоты
              children: [
                Icon(Icons.construction_outlined, color: Theme.of(context).colorScheme.primary), // Иконка "в разработке"
                SizedBox(width: 8),
                Text('В разработке'),
              ],
            ),
            content: Text('Раздел "Новости" скоро появится! Работаю в поте лица (честно ¯\\_(ツ)_/¯)'),
            actions: <Widget>[
              TextButton(
                child: Text('Понятно'),
                onPressed: () {
                  Navigator.of(context).pop(); // Закрыть диалог
                },
              ),
            ],
            shape: RoundedRectangleBorder( // Слегка скруглим углы диалога
              borderRadius: BorderRadius.circular(12.0)
            ),
          );
        },
      );
    } else {
      // --- Если нажата ДРУГАЯ вкладка (Расписание или Настройки) ---
      // Переключаем экран как обычно
      setState(() {
        _selectedIndex = index;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar теперь можно разместить здесь, если он общий для всех вкладок,
      // либо оставить его внутри каждого экрана (_widgetOptions)
      // Пример общего AppBar:
      // appBar: AppBar(
      //   title: Text(_selectedIndex == 0 ? 'Расписание' : 'Новости'),
      // ),

      // Тело Scaffold - отображает выбранный экран
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

        // Нижняя панель навигации
        bottomNavigationBar: NavigationBar(
        // Имя параметра изменилось: currentIndex -> selectedIndex
        selectedIndex: _selectedIndex,
        // Имя колбэка изменилось: onTap -> onDestinationSelected
        onDestinationSelected: _onItemTapped, // Используем тот же метод
        // backgroundColor: Theme.of(context).colorScheme.surface,
        // Вместо 'items' используется 'destinations',
        // а вместо BottomNavigationBarItem -> NavigationDestination
        destinations: const <Widget>[
          NavigationDestination(
            // Рекомендуется использовать outlined иконки для неактивного состояния
            icon: Icon(Icons.schedule_outlined),
            // И заполненные для активного (если нужно различие)
            selectedIcon: Icon(Icons.schedule),
            label: 'Расписание',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Новости',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],

        // --- УДАЛЯЕМ старые параметры стиля ---
        // selectedItemColor, unselectedItemColor, type, showSelectedLabels, showUnselectedLabels
        // Стиль NavigationBar обычно определяется через ThemeData -> navigationBarTheme
        // Например, цвет индикатора, фона, иконок и текста задается там

        // --- ОПЦИОНАЛЬНО: Дополнительные настройки NavigationBar ---
        // animationDuration: Duration(milliseconds: 500), // Длительность анимации
        // labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // Или .onlyShowSelected / .alwaysHide
        // indicatorColor: Colors.amber, // Явное задание цвета индикатора (лучше через тему)
        // backgroundColor: Colors.red, // Явное задание цвета фона (лучше через тему)
      ),    );
  }
}