import 'package:flutter/material.dart';
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
      theme: ThemeData(fontFamily: 'JetBrains Mono'),
      home: ScheduleScreen(),
    );
  }
}
