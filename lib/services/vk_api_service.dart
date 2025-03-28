// Файл: lib/services/vk_api_service.dart
import '../models/vk_post.dart'; // Импортируем модель

class VkApiService {
  // --- Метод-заглушка ---
  // В будущем этот метод будет асинхронно получать данные
  // с твоего прокси-сервера, который обращается к VK API
  Future<List<VkPost>> fetchVkNews() async {
    // Имитируем задержку сети
    await Future.delayed(Duration(milliseconds: 800));

    // Возвращаем заранее подготовленный список постов (Mock Data)
    // Замени этот список на более реалистичный, если хочешь
    return [
      VkPost(
        id: 1,
        text: '''🌟 Приглашаем на День открытых дверей в Алтайский промышленно-экономический колледж! 🌟

📅 Дата: 29 марта
🕚 Время: 12:00, мастер-классы с 11.00

Погрузитесь в мир специальностей и возможностей! На нашем Дне открытых дверей вас ждут:

✨ Мастер-классы; 
🎤 Презентации коллективов и объединений колледжа; 
🤝 Возможность задать вопросы и узнать больше о наших специальностях. 

Не упустите шанс познакомиться с нашим колледжем, узнать о будущих профессиях и сделать правильный выбор для своего будущего!

Ждем вас! 💼📚''',
        date: DateTime.now().subtract(Duration(hours: 5)),
        likesCount: 15,
        commentsCount: 2,
        imageUrls: [
          'https://sun4-20.userapi.com/impg/VeD58fDJ17VoEfjzQOqSYwE8gl43wQjO1YJ0_A/XvXoROOAXO0.jpg?size=2560x1808&quality=95&sign=7d44a428b7c42257ee8d6fd2cd4bad41&type=album', // Замени на реальные URL картинок или оставь заглушки
        ],
      ),
      VkPost(
        id: 2,
        text: 'Студенты группы 9ОИБ231 заняли первое место на олимпиаде по программированию! 🏆 Поздравляем ребят и их наставника!\n\n#АПЭК #Победа #Программирование',
        date: DateTime.now().subtract(Duration(days: 1)),
        likesCount: 45,
        commentsCount: 8,
        repostsCount: 3,
        imageUrls: [
          'https://via.placeholder.com/600/771796',
          'https://via.placeholder.com/600/24f355',
        ],
      ),
      VkPost(
        id: 3,
        text: 'Фотоотчет с прошедшего Дня открытых дверей. Спасибо всем, кто пришел!\nБольше фото в альбоме: [ссылка]', // VK ссылки можно будет сделать кликабельными позже
        date: DateTime.now().subtract(Duration(days: 2, hours: 3)),
        likesCount: 30,
        commentsCount: 1,
        imageUrls: [
          'https://via.placeholder.com/600/d32776',
          'https://via.placeholder.com/600/f66b97',
          'https://via.placeholder.com/600/56a8c2',
        ],
      ),
       VkPost(
        id: 4,
        text: 'Обновленное меню в столовой на эту неделю. Приятного аппетита!',
        date: DateTime.now().subtract(Duration(days: 3)),
        likesCount: 22,
        commentsCount: 5,
        // Пост без картинок
      ),
    ];
  }

  // В будущем здесь появятся методы для реального взаимодействия с API
  // Future<List<VkPost>> fetchVkNewsFromApi(int count, int offset) async { ... }
}