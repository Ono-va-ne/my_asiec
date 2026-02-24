import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/main/schedule_screen.dart';
import 'pages/main/homework_screen.dart';
import 'pages/main/handbook_specs_screen.dart';
import 'pages/main/more_screen.dart';

import '../models/homework.dart';
// import '../data/group_uploader.dart';

import 'dart:async';
import '../services/notification_service.dart';
import '../services/pomodoro_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/settings_service.dart';
import '../utils/logger_setup.dart';
// import 'package:http/http.dart' as http;


void main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();


      await NotificationService().init();
      WidgetsFlutterBinding.ensureInitialized();
      pomodoroService.init(); // Инициализируем сервис Pomodoro
      await initializeDateFormatting('ru_RU', null);

      WidgetsFlutterBinding.ensureInitialized();
      await settingsService.loadSettings();
      WidgetsFlutterBinding.ensureInitialized();
      await Supabase.initialize(
        url: 'https://zffxqnxjxhnmcdvifyyc.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmZnhxbnhqeGhubWNkdmlmeXljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzNTY3NDMsImV4cCI6MjA3MTkzMjc0M30.Tan-ExOBrf3U8dxQyIlIZmuY_DHkvCFCk2QdTmFN_Sk',
      );
      await Firebase.initializeApp();
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HomeworkAdapter());
      }
      await Hive.openBox<Homework>('localHomeworkBox');
      // аплоад списка групп в firebase
      // final uploader = GroupDataUploader();
      // uploader.uploadGroups();
      FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
      await TeXRenderingServer.start();
      runApp(MyApp());
    },
    (error, stackTrace) {
      recordError(error, stackTrace);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _createThemeData(
    Brightness brightness,
    Color? accentColor,
    ColorScheme? dynamicColors,
  ) {
    final baseColorScheme =
        dynamicColors ??
        ColorScheme.fromSeed(
          seedColor: accentColor ?? Colors.blue,
          brightness: brightness,
        );

    final scaffoldBackgroundColor =
        brightness == Brightness.light ? Colors.grey[100] : Color(0xFF121212);
    final cardBackgroundColor =
        brightness == Brightness.light ? Colors.white : Colors.grey[850];
    final appBarBackgroundColor =
        brightness == Brightness.light
            ? baseColorScheme.surface
            : baseColorScheme.surface;

    return ThemeData(
      colorScheme: baseColorScheme,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'RobotoFlex',

      scaffoldBackgroundColor: scaffoldBackgroundColor,

      cardTheme: CardThemeData(
        elevation: 1.0,
        color: cardBackgroundColor,
        margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: brightness == Brightness.light ? 1.0 : 0.0,
        backgroundColor: appBarBackgroundColor,
        foregroundColor: baseColorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: baseColorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: settingsService.themeModeNotifier,
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<Color?>(
              valueListenable: settingsService.accentColorNotifier,
              builder: (context, accentColor, _) { 
                return ValueListenableBuilder<Locale?>(
                  valueListenable: settingsService.localeNotifier,
                  builder: (context, locale, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: settingsService.materialYouNotifier,
                      builder: (context, isMaterialYouEnabled, _) {
                        return MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: "My ASIEC",
                          theme: _createThemeData(
                            Brightness.light,
                            accentColor,
                            isMaterialYouEnabled ? lightDynamic : null,
                          ),
                          darkTheme: _createThemeData(
                            Brightness.dark,
                            accentColor,
                            isMaterialYouEnabled ? darkDynamic : null,
                          ),
                          themeMode: themeMode,
                          locale: locale,
                          localizationsDelegates: [
                            GlobalMaterialLocalizations
                                .delegate, // Локализация для Material виджетов
                            GlobalWidgetsLocalizations
                                .delegate, // Локализация для базовых виджетов (направление текста и т.д.)
                            GlobalCupertinoLocalizations
                                .delegate, // Локализация для Cupertino (iOS) виджетов (иногда нужна и для Material)
                            AppLocalizations
                                .delegate,
                          ],
                          supportedLocales: [
                            const Locale('ru', ''),
                            const Locale('en', ''),
                          ],
                          onGenerateTitle: (context) => AppLocalizations.of(context)!
                              .myASIEC,
                          home: MainScreen(),
                          navigatorKey: NavigatorService.navigatorKey, // Добавляем ключ навигатора
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ScheduleScreen(),
    HomeworkScreen(),
    SpecialtiesScreen(),
    MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.access_time),
            selectedIcon: const Icon(Icons.access_time_filled),
            label: AppLocalizations.of(context)!.scheduleScreen,
          
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: AppLocalizations.of(context)!.taskScreen,
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: AppLocalizations.of(context)!.handbookScreen,
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: AppLocalizations.of(context)!.moreScreen,
          ),
        ],
      ),
    );
  }
}
