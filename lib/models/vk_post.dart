class VkPost {
  final int id; // Уникальный ID поста
  final int ownerId;
  final String text; // Текст поста
  final DateTime date; // Дата публикации
  final List<String> imageUrls; // Список URL картинок
  final int likesCount; // Количество лайков (пример)
  final int commentsCount; // Количество комментариев (пример)
  final int repostsCount; // Количество репостов (пример)

  VkPost({
    required this.id,
    required this.ownerId,
    required this.text,
    required this.date,
    this.imageUrls = const [], // По умолчанию пустой список
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
  });

  // В будущем здесь можно добавить factory constructor .fromJson()
  // для парсинга реального ответа от VK API (или твоего прокси)
}