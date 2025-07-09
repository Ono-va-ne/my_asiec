import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vk_post.dart'; // Импортируем модель

class VkApiService {
  // --- Метод-заглушка ---
  // В будущем этот метод будет асинхронно получать данные
  // с твоего прокси-сервера, который обращается к VK API
//   Future<List<VkPost>> fetchVkNews() async {
//     // Имитируем задержку сети
//     await Future.delayed(Duration(milliseconds: 800));

//     const groupId = -201142801;

//     // Возвращаем заранее подготовленный список постов (Mock Data)
//     // Замени этот список на более реалистичный, если хочешь
//     return [
//       VkPost(
//         id: 5687,
//         ownerId: groupId,
//         text: '''🌟 Приглашаем на День открытых дверей в Алтайский промышленно-экономический колледж! 🌟

// 📅 Дата: 29 марта
// 🕚 Время: 12:00, мастер-классы с 11.00

// Погрузитесь в мир специальностей и возможностей! На нашем Дне открытых дверей вас ждут:

// ✨ Мастер-классы; 
// 🎤 Презентации коллективов и объединений колледжа; 
// 🤝 Возможность задать вопросы и узнать больше о наших специальностях. 

// Не упустите шанс познакомиться с нашим колледжем, узнать о будущих профессиях и сделать правильный выбор для своего будущего!

// Ждем вас! 💼📚''',
//         date: DateTime.now().subtract(Duration(hours: 5)),
//         likesCount: 15,
//         commentsCount: 2,
//         imageUrls: [
//           'https://sun4-20.userapi.com/impg/VeD58fDJ17VoEfjzQOqSYwE8gl43wQjO1YJ0_A/XvXoROOAXO0.jpg?size=2560x1808&quality=95&sign=7d44a428b7c42257ee8d6fd2cd4bad41&type=album', // Замени на реальные URL картинок или оставь заглушки
//         ],
//       ),
//       VkPost(
//         id: 2,
//         ownerId: groupId,
//         text: 'Студенты группы 9ОИБ231 заняли первое место на олимпиаде по программированию! 🏆 Поздравляем ребят и их наставника!\n\n#АПЭК #Победа #Программирование',
//         date: DateTime.now().subtract(Duration(days: 1)),
//         likesCount: 45,
//         commentsCount: 8,
//         repostsCount: 3,
//         imageUrls: [
//           'https://via.placeholder.com/600/771796',
//           'https://via.placeholder.com/600/24f355',
//         ],
//       ),
//       VkPost(
//         id: 3,
//         ownerId: groupId,
//         text: 'Фотоотчет с прошедшего Дня открытых дверей. Спасибо всем, кто пришел!\nБольше фото в альбоме: [ссылка]', // VK ссылки можно будет сделать кликабельными позже
//         date: DateTime.now().subtract(Duration(days: 2, hours: 3)),
//         likesCount: 30,
//         commentsCount: 1,
//         imageUrls: [
//           'https://via.placeholder.com/600/d32776',
//           'https://via.placeholder.com/600/f66b97',
//           'https://via.placeholder.com/600/56a8c2',
//         ],
//       ),
//        VkPost(
//         id: 4,
//         ownerId: groupId,
//         text: 'Обновленное меню в столовой на эту неделю. Приятного аппетита!',
//         date: DateTime.now().subtract(Duration(days: 3)),
//         likesCount: 22,
//         commentsCount: 5,
//         // Пост без картинок
//       ),
//     ];
//   }

  /// Получение новостей из группы ВК через VK API
  Future<List<VkPost>> fetchVkNewsFromApi({
    int count = 10,
    int offset = 0,
  }) async {
    const groupId = -225681095; // ID вашей группы
    const accessToken = 'vk1.a.fFOvt3oMBHTaCsoQilZRJmu1Co77z2t1i4FTQmvy5Ky9jmLr71W5bOLF7XycpxZdIAabkNkQn61fsn8KKqreJ0QPAR5gcyk-Y7CS260leN_iXkBynSE_QfnSEUGvLrwQa1MAX6wyseL984K1KDTPosBw5o38dYch0F9MpxITg3JbNn5HdCdK_2I79o6gHRpXTCB37JhvD7FFfNgPoeW99A'; // <-- Вставьте сюда ваш access_token
    const apiVersion = '5.199';

    final url = Uri.parse(
      'https://api.vk.com/method/wall.get?owner_id=$groupId&count=$count&offset=$offset&access_token=$accessToken&v=$apiVersion',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Ошибка запроса к VK API: ${response.statusCode}');
    }
    final data = json.decode(response.body);
    if (data['error'] != null) {
      throw Exception('VK API error: ${data['error']['error_msg']}');
    }
    final List items = data['response']['items'];
    return items.map<VkPost>((item) {
      // Извлекаем картинки (attachments)
      List<String> images = [];
      if (item['attachments'] != null) {
        for (var att in item['attachments']) {
          if (att['type'] == 'photo') {
            // Берем максимальный размер
            var sizes = att['photo']['sizes'] as List;
            sizes.sort((a, b) => (b['width'] as int).compareTo(a['width'] as int));
            images.add(sizes.first['url']);
          }
        }
      }
      return VkPost(
        id: item['id'],
        ownerId: item['owner_id'],
        text: item['text'] ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(item['date'] * 1000),
        likesCount: item['likes']?['count'] ?? 0,
        commentsCount: item['comments']?['count'] ?? 0,
        repostsCount: item['reposts']?['count'] ?? 0,
        imageUrls: images,
      );
    }).toList();
  }

  // В будущем здесь появятся методы для реального взаимодействия с API
  // Future<List<VkPost>> fetchVkNewsFromApi(int count, int offset) async { ... }
}