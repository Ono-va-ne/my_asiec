import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_asiec_lite/pages/schedule_screen.dart';
import 'package:my_asiec_lite/pages/news_screen.dart';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
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
  // Применяем обход проверки SSL глобально
  HttpOverrides.global = MyHttpOverrides(); // <-- ДОБАВЬ ЭТУ СТРОКУ

  // Инициализация локали (если используешь intl)
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);

  runApp(MyApp()); // Запускаем твое приложение
}

// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "МойАПЭК lite",
      theme: ThemeData(
        fontFamily: 'JetBrains Mono'),
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
    NewsScreen(),     // Новый экран новостей
  ];

  // Метод для смены вкладки
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule), // Иконка расписания
            label: 'Расписание',      // Подпись
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined), // Иконка новостей
            label: 'Новости',               // Подпись
          ),
        ],
        currentIndex: _selectedIndex,   // Какая вкладка сейчас активна
        selectedItemColor: Colors.blue, // Цвет выбранной иконки/текста
        unselectedItemColor: Colors.grey, // Цвет невыбранной иконки/текста
        onTap: _onItemTapped,         // Что делать при нажатии на вкладку
        // type: BottomNavigationBarType.fixed, // Или .shifting, влияет на анимацию и вид
        // showSelectedLabels: true,
        // showUnselectedLabels: true,
      ),
    );
  }
}