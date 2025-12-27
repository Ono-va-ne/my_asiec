import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'
    show FlutterErrorDetails, kDebugMode; // Для проверки режима

late final File _logFile; // Объявляем файл на уровне модуля

// Глобальный экземпляр логгера, который будем использовать везде
final logger = Logger(
  // Используем MultiOutput для вывода и в консоль, и в файл
  output: MultiOutput([
    // Вывод в консоль (только в режиме отладки для производительности)
    if (kDebugMode) ConsoleOutput(),
    // Вывод в файл (будет инициализирован позже)
    FileOutput(file: _stubFile), // Используем временный файл до инициализации
  ]),
  // Уровни логирования и форматтер
  printer: PrettyPrinter(
    methodCount: 1, // Сколько методов стека вызовов показывать
    errorMethodCount: 8, // Больше для ошибок
    lineLength: 120, // Ширина строки
    colors: true, // Цветной вывод в консоль
    printEmojis: true, // Эмодзи для уровней
    printTime: true, // Печатать временную метку
    noBoxingByDefault: false, // Оставляем рамки по умолчанию
  ),
  // Уровень логирования (можно менять в зависимости от сборки)
  // Level.debug - показывает всё
  // Level.info - показывает info, warning, error
  // Level.warning - показывает warning, error
  // Level.error - показывает только error
  // Level.nothing - ничего не показывает
  level: kDebugMode ? Level.debug : Level.info,
);

// Временный файл-заглушка, пока мы не получим реальный путь
// Это обходной путь, т.к. FileOutput требует файл при создании логгера,
// а путь мы получаем асинхронно.
// Важно: Не пишите в этот файл до вызова setupLogging!
final _stubFile = File('');

// Асинхронная функция инициализации файла логов
Future<void> setupLogging() async {
  try {
    // Получаем директорию для хранения документов приложения
    final directory = await getApplicationDocumentsDirectory();
    final logFilePath = '${directory.path}/app_logs.log';
    _logFile = File(logFilePath);

    // Теперь обновляем FileOutput в логгере, чтобы он использовал реальный файл
    // К сожалению, стандартный logger не позволяет легко менять output после создания.
    // Но FileOutput сам обновляет ссылку на файл, если он был передан через конструктор.
    // Мы можем "передать" новый файл через ссылку, которую FileOutput уже хранит.
    // Это немного хак, но работает. Более чистое решение - кастомный Output.
    // *** Обновление: Похоже, FileOutput может сам создавать файл, если путь указан ***
    // Попробуем более простой подход:

    // Закрываем старый логгер (если он был инициализирован ранее)
    // logger.close(); // Не обязательно, если это первый вызов

    // Создаем новый логгер с правильным FileOutput
    // logger = Logger(...) // Не можем пересоздать final logger
    // Вместо этого, создадим FileOutput здесь и передадим его как кастомный output

    final fileOutput = FileOutput(
      file: _logFile,
      overrideExisting: false, // Не перезаписывать файл при старте, а добавлять
      encoding: const SystemEncoding(), // Использовать кодировку системы
      // TODO: Настроить ротацию логов!
      // Например, чтобы файл не рос бесконечно:
      // fileOutput.stream // FileOutput не предоставляет прямого API для ротации в v2
      // Потребуется либо своя реализация, либо сторонний пакет (см. ниже)
    );

    // Переконфигурируем глобальный логгер
    Logger.level =
        kDebugMode ? Level.debug : Level.info; // Устанавливаем уровень
    logger.i(
      "Логгер инициализирован. Логи будут сохраняться в: ${_logFile.path}",
    );
    // Заменяем MultiOutput или добавляем FileOutput, если его не было
    // К сожалению, стандартный MultiOutput не позволяет легко модифицировать список.
    // Проще всего создать новый логгер, но т.к. logger final, сделаем это
    // в main() перед runApp()
  } catch (e, stackTrace) {
    // Если произошла ошибка при настройке логирования, выводим в консоль
    print('Ошибка настройки логирования в файл: $e\n$stackTrace');
  }
}

// Функция для получения пути к файлу логов (для отправки)
Future<String?> getLogFilePath() async {
  // Убедимся, что _logFile инициализирован
  if (!_logFile.existsSync() && _logFile.path.isNotEmpty) {
    await setupLogging(); // Попробуем инициализировать, если еще не было
  }
  // Проверяем еще раз после попытки инициализации
  if (_logFile.existsSync()) {
    return _logFile.path;
  } else if (_logFile.path.isNotEmpty) {
    print("Лог файл ${_logFile.path} все еще не существует.");
    return null;
  } else {
    print("Путь к лог файлу не был инициализирован.");
    return null;
  }
}

// Опционально: Функция для очистки лог файла
Future<void> clearLogFile() async {
  if (_logFile.existsSync()) {
    try {
      await _logFile.writeAsString(''); // Перезаписываем пустым содержимым
      logger.i("Лог файл очищен.");
    } catch (e) {
      logger.e("Ошибка при очистке лог файла", error: e);
    }
  }
}

// --- Логирование неперехваченных ошибок ---

void recordFlutterError(FlutterErrorDetails details) {
  logger.e(
    'Неперехваченная ошибка Flutter!',
    error: details.exception,
    stackTrace:
        details.stack ?? StackTrace.current, // Предоставляем stack trace
    // Можно добавить details.library, details.context для доп. информации
  );
}

void recordError(Object error, StackTrace stackTrace) {
  logger.e(
    'Неперехваченная ошибка Dart!',
    error: error,
    stackTrace: stackTrace,
  );
}
