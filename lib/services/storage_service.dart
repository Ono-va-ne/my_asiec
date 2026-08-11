import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CacheCategory {
  final String id;
  final String title;
  final int sizeInBytes;
  final Color color;
  final IconData icon;

  CacheCategory({
    required this.id,
    required this.title,
    required this.sizeInBytes,
    required this.color,
    required this.icon,
  });
}

class StorageService {
  // Получить размер категорий кэша
  static Future<List<CacheCategory>> getCacheBreakdown() async {
    final tempDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();

    // Симулируем/читаем реальные директории под каждую категорию
    final mediaDir = Directory(tempDir.path);
    final messagesDir = Directory('${docDir.path}/messages_cache');
    final scheduleDir = Directory('${docDir.path}/schedule_cache');
    final homeworkDir = Directory('${docDir.path}/homework_cache');

    int mediaSize = await _getDirSize(mediaDir);
    int messagesSize = await _getDirSize(messagesDir);
    int scheduleSize = await _getDirSize(scheduleDir);
    int homeworkSize = await _getDirSize(homeworkDir);

    return [
      CacheCategory(
        id: 'media',
        title: 'Медиа и файлы',
        sizeInBytes: mediaSize,
        color: Colors.amber.shade700,
        icon: Icons.perm_media_outlined,
      ),
      CacheCategory(
        id: 'messages',
        title: 'Сообщения',
        sizeInBytes: messagesSize,
        color: Colors.blue,
        icon: Icons.chat_bubble_outline,
      ),
      CacheCategory(
        id: 'schedule',
        title: 'Расписание',
        sizeInBytes: scheduleSize,
        color: Colors.green,
        icon: Icons.calendar_today_outlined,
      ),
      CacheCategory(
        id: 'homework',
        title: 'Задания',
        sizeInBytes: homeworkSize,
        color: Colors.purple,
        icon: Icons.assignment_outlined,
      ),
    ];
  }

  // Рекурсивный расчет размера папки
  static Future<int> _getDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      print('Ошибка измерения папки: $e');
    }
    return totalSize;
  }

  // Очистка выбранной категории
  static Future<void> clearCategoryCache(String categoryId) async {
    final tempDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();

    switch (categoryId) {
      case 'media':
        if (await tempDir.exists()) await _deleteDirContent(tempDir);
        break;
      case 'messages':
        final dir = Directory('${docDir.path}/messages_cache');
        if (await dir.exists()) await _deleteDirContent(dir);
        break;
      case 'schedule':
        final dir = Directory('${docDir.path}/schedule_cache');
        if (await dir.exists()) await _deleteDirContent(dir);
        break;
      case 'homework':
        final dir = Directory('${docDir.path}/homework_cache');
        if (await dir.exists()) await _deleteDirContent(dir);
        break;
    }
  }

  // Очистка всего кэша приложения
  static Future<void> clearAllCache() async {
    final tempDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();

    await _deleteDirContent(tempDir);
    await _deleteDirContent(Directory('${docDir.path}/messages_cache'));
    await _deleteDirContent(Directory('${docDir.path}/schedule_cache'));
    await _deleteDirContent(Directory('${docDir.path}/homework_cache'));
  }

  static Future<void> _deleteDirContent(Directory dir) async {
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: false)) {
          await entity.delete(recursive: true);
        }
      }
    } catch (e) {
      print('Ошибка удаления кэша: $e');
    }
  }

  // Форматирование байт в Б, КБ, МБ, ГБ
  static String formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}