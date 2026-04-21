
// f:\Projects\my_asiec\lib\utils\logger_setup_web.dart

import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show FlutterErrorDetails;

// Глобальный экземпляр логгера для веба (только консоль)
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
  level: Level.debug,
);

// Пустые функции-заглушки, чтобы компилятор не ругался
Future<void> setupLogging() async {
  // В вебе логирование в файл не нужно
  logger.i("Logging initialized for web (console only).");
}

Future<String?> getLogFilePath() async {
  return null; // Нет файла логов в вебе
}

Future<void> clearLogFile() async {
  // Ничего не делаем
}

void recordFlutterError(FlutterErrorDetails details) {
  logger.e(
    'Uncaught Flutter error!',
    error: details.exception,
    stackTrace: details.stack,
  );
}

void recordError(Object error, StackTrace stackTrace) {
  logger.e(
    'Uncaught Dart error!',
    error: error,
    stackTrace: stackTrace,
  );
}
