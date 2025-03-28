import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_asiec_lite/pages/schedule_screen.dart';
import 'dart:io';
// import 'package:intl/intl.dart';
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
  // WidgetsFlutterBinding.ensureInitialized();
  // await initializeDateFormatting('ru_RU', null);

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
      home: ScheduleScreen(),
    );
  }
}
