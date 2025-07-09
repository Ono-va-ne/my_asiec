// В файле lib/screens/homework_view_screen.dart

import 'package:flutter/material.dart';
import '../models/homework.dart'; // Импортируем нашу модель Homework
import 'homework_edit_screen.dart'; // Импортируем экран редактирования ДЗ
import 'package:intl/intl.dart'; // Для форматирования даты
import 'dart:io'; // Для работы с File
import 'package:open_file/open_file.dart'; // Для открытия файла в приложении'

// Возможно, понадобится cached_network_image для удаленных фото
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart'; // Для получения пути к директории документов

class HomeworkViewScreen extends StatelessWidget {
  // Экран принимает объект Homework для отображения
  final Homework homeworkEntry;

  const HomeworkViewScreen({Key? key, required this.homeworkEntry}) : super(key: key);

  // Вспомогательный метод для отображения одного фото
  Widget _buildPhotoWidget(String photoPathOrUrl) {
    // TODO: Здесь нужно будет различать локальные пути и URLы Firebase Storage
    // Сейчас мы знаем, что для локальных записей здесь будут ПУТИ, для удаленных - URLы (пока пустые)
    // Если homeworkEntry.isLocal, это локальный путь.
    // Если !homeworkEntry.isLocal, это URL из Firebase Storage (сейчас null/пустой).

    if (homeworkEntry.isLocal) {
      // --- Отображаем ЛОКАЛЬНОЕ фото по пути ---
      final File localFile = File(photoPathOrUrl);
      return FutureBuilder<bool>( // Используем FutureBuilder, чтобы проверить существование файла асинхронно
        future: localFile.exists(), // Проверяем, существует ли файл
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data == true) {
            // Если файл существует, отображаем его и делаем кликабельным
            return GestureDetector(
              onTap: () async {
                // Используем open_file для открытия файла
                try {
                  final result = await OpenFile.open(localFile.path);
                  // print('OpenFile result: ${result.message}');
                } catch (e) {
                  print('Error opening file: $e');
                  // Опционально: показать SnackBar или диалог пользователю
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось открыть файл. Убедитесь, что установлено приложение для просмотра этого типа файлов.')),
                  );
                }
              },
              child: Image.file(
                localFile,
                fit: BoxFit.cover, // Как изображение будет вписываться
                width: 100, // Ширина миниатюры
                height: 100, // Высота миниатюры
              ),
            );
          } else {
            // Если файл не существует или ошибка
            return const SizedBox( // Пустой бокс или иконка ошибки
              width: 100, height: 100,
              child: Icon(Icons.broken_image, color: Colors.grey),
            );
          }
        },
      );

    } else {
      // --- Отображаем УДАЛЕННОЕ фото по URL ---
      // Пока что фото для удаленных записей не загружаются/сохраняются
      // Просто показываем заглушку или иконку, если URL пустой/нет.
      if (photoPathOrUrl.isNotEmpty) {
         // TODO: Реализовать загрузку из Firebase Storage по URL
         // С использованием CachedNetworkImage
         print('Внимание: Попытка отобразить удаленное фото по URL: $photoPathOrUrl');
         return const SizedBox( // Заглушка для удаленных фото
           width: 100, height: 100,
           child: Icon(Icons.cloud_off, color: Colors.grey), // Иконка, показывающая, что фото удаленное/недоступно
         );
         /*
         // Пример с CachedNetworkImage (потребуется добавить пакет):
         return CachedNetworkImage(
           imageUrl: photoPathOrUrl,
           fit: BoxFit.cover,
           width: 100,
           height: 100,
           placeholder: (context, url) => CircularProgressIndicator(), // Пока грузится
           errorWidget: (context, url, error) => Icon(Icons.error), // Если ошибка
         );
         */
      } else {
         return const SizedBox.shrink(); // Не отображаем ничего, если URL пустой
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Домашнее задание'), // Заголовок - предмет ДЗ
        actions: [
          // --- Кнопка "Редактировать" ---
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: () {
              // При нажатии открываем экран редактирования, передавая текущий объект ДЗ
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeworkEditScreen(
                    homeworkEntry: homeworkEntry, // <--- ПЕРЕДАЕМ ОБЪЕКТ ДЗ ДЛЯ РЕДАКТИРОВАНИЯ!
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Используем ListView для прокрутки
          children: [
            // --- Отображаем предмет и подгруппу (если есть) ---
            Text(
              '${homeworkEntry.discipline}${homeworkEntry.subgroup != null ? ' / ${homeworkEntry.subgroup}' : ''}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), // Стиль заголовка
            ),
            const SizedBox(height: 8.0),
            Text(
              'Срок сдачи: ${DateFormat('dd.MM.yyyy').format(homeworkEntry.dueDate)} ${homeworkEntry.isLocal ? '(Локально)' : ''}', // Срок сдачи
              style: Theme.of(context).textTheme.bodyLarge, // Стиль подзаголовка
            ),
            const SizedBox(height: 16.0),
            Text(
              'Задание:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Стиль заголовка задания
            ),
             const SizedBox(height: 4.0),
            Text(
              homeworkEntry.task, // Текст задания
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),

            // --- Отображаем фото, если они есть ---
            if (homeworkEntry.photoUrls != null && homeworkEntry.photoUrls!.isNotEmpty)
              Column( // Используем Column для отображения списка фото
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Фотографии:',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8.0),
                   // Используем Wrap или GridView для отображения миниатюр
                   // Wrap - проще, если фото немного
                   Wrap( // Wrap автоматически переносит элементы на новую строку
                      spacing: 8.0, // Горизонтальный отступ между фото
                      runSpacing: 8.0, // Вертикальный отступ между рядами фото
                      children: homeworkEntry.photoUrls!.map((photoPathOrUrl) {
                         return _buildPhotoWidget(photoPathOrUrl); // Вызываем вспомогательный метод для каждого фото
                      }).toList(),
                   ),
                 ],
              ),
          ],
        ),
      ),
    );
  }
}