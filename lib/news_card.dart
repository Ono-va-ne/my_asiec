// Файл: lib/news_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования даты/времени
import 'models/vk_post.dart'; // Импортируем модель

class NewsCard extends StatelessWidget {
  final VkPost post;

  const NewsCard({super.key, required this.post});

  // Хелпер для форматирования даты
  String _formatDateTime(DateTime dt) {
     final now = DateTime.now();
     final difference = now.difference(dt);

     if (difference.inDays == 0 && dt.day == now.day) {
        return 'Сегодня в ${DateFormat('HH:mm').format(dt)}';
     } else if (difference.inDays == 1 || (difference.inDays == 0 && dt.day == now.day -1)) {
        return 'Вчера в ${DateFormat('HH:mm').format(dt)}';
     } else if (dt.year == now.year) {
        // Используем русскую локаль для названия месяца
        return '${DateFormat('d MMMM в HH:mm', 'ru_RU').format(dt)}';
     } else {
        return '${DateFormat('d MMMM yyyy в HH:mm', 'ru_RU').format(dt)}';
     }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Дата поста ---
            Text(
              _formatDateTime(post.date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.0,
              ),
            ),
            SizedBox(height: 8.0),

            // --- Текст поста ---
            if (post.text.isNotEmpty) // Показываем текст, только если он есть
              Text(
                post.text,
                style: TextStyle(fontSize: 14.0, height: 1.4), // Немного увеличим межстрочный интервал
              ),
            if (post.text.isNotEmpty) SizedBox(height: 12.0),

            // --- Изображения ---
            if (post.imageUrls.isNotEmpty)
              _buildImageGrid(context, post.imageUrls),
            if (post.imageUrls.isNotEmpty) SizedBox(height: 12.0),

            // --- Разделитель и Статистика (Лайки/Комменты/Репосты) ---
            Divider(height: 1.0),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Выравниваем влево
                children: [
                  _buildStatIcon(Icons.favorite_border, post.likesCount),
                  SizedBox(width: 16.0),
                  _buildStatIcon(Icons.chat_bubble_outline, post.commentsCount),
                   SizedBox(width: 16.0),
                  _buildStatIcon(Icons.repeat, post.repostsCount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для отображения иконок статистики
  Widget _buildStatIcon(IconData icon, int count) {
    // Не отображаем иконку, если счетчик равен 0
    if (count <= 0) return SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 18.0, color: Colors.grey[700]),
        SizedBox(width: 4.0),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // Виджет для отображения сетки изображений
  Widget _buildImageGrid(BuildContext context, List<String> imageUrls) {
    // Определяем количество колонок в сетке
    // 1 картинка - 1 колонка
    // 2 или 4 картинки - 2 колонки
    // 3 или >4 картинок - можно тоже 2 или 3, пока оставим 2
    int crossAxisCount = 1;
    if (imageUrls.length >= 2) {
      crossAxisCount = 2;
    }
    // Можно добавить логику для 3 колонок, если картинок много

    return GridView.builder(
      shrinkWrap: true, // Обязательно внутри Column/ListView
      physics: NeverScrollableScrollPhysics(), // Отключаем скролл сетки
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4.0, // Пространство между картинками по горизонтали
        mainAxisSpacing: 4.0,  // Пространство между картинками по вертикали
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect( // Скругляем углы у картинок
           borderRadius: BorderRadius.circular(8.0),
           child: Image.network(
              imageUrls[index],
              fit: BoxFit.fitWidth, // Картинка будет заполнять ячейку
              // Добавляем индикатор загрузки и обработчик ошибок
              loadingBuilder: (context, child, loadingProgress) {
                 if (loadingProgress == null) return child; // Картинка загружена
                 return Container(
                    color: Colors.grey[200], // Фон во время загрузки
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null, // Показываем прогресс, если возможно
                      ),
                    ),
                 );
              },
              errorBuilder: (context, error, stackTrace) {
                 return Container( // Заглушка при ошибке загрузки
                    color: Colors.grey[200],
                    child: Center(
                       child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey[400],
                       ),
                    ),
                 );
              },
           ),
        );
      },
    );
  }
}