// Файл: lib/news_screen.dart
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Для форматирования даты

// Импортируем сервис и модель
import 'package:my_asiec_lite/services/vk_api_service.dart';
import 'package:my_asiec_lite/models/vk_post.dart';
// Импортируем виджет карточки поста (создадим ниже)
import 'package:my_asiec_lite/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final VkApiService _vkApiService = VkApiService(); // Создаем экземпляр сервиса
  late Future<List<VkPost>> _newsFuture; // Future для хранения результата загрузки

  @override
  void initState() {
    super.initState();
    // Запускаем загрузку новостей при инициализации экрана
    _loadNews();
  }

  void _loadNews() {
    // Присваиваем Future переменной состояния
    // FutureBuilder будет использовать этот Future для отображения данных
    _newsFuture = _vkApiService.fetchVkNews();
  }

  // Функция для обновления (например, потянуть вниз для обновления)
  Future<void> _refreshNews() async {
    setState(() {
      // Перезапускаем загрузку, FutureBuilder автоматически подхватит новый Future
      _loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar лучше убрать отсюда, если он есть в MainScreen,
      // чтобы не было двойного AppBar
       appBar: AppBar(
         title: Text('Новости колледжа'),
         backgroundColor: Colors.white, // Или цвет твоей темы
         foregroundColor: Colors.black,
         elevation: 1.0,
       ),
      body: RefreshIndicator(
        // Добавляем возможность обновления списка потягиванием вниз
        onRefresh: _refreshNews,
        child: FutureBuilder<List<VkPost>>(
          future: _newsFuture, // Используем Future, который мы загружаем
          builder: (context, snapshot) {
            // --- Случай 1: Данные еще загружаются ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            // --- Случай 2: Произошла ошибка ---
            else if (snapshot.hasError) {
              print('Ошибка загрузки новостей: ${snapshot.error}'); // Для отладки
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Text('Не удалось загрузить новости 😥\n${snapshot.error}', textAlign: TextAlign.center),
                        SizedBox(height: 16),
                        ElevatedButton(
                           onPressed: _refreshNews, // Кнопка для повторной попытки
                           child: Text('Попробовать снова'),
                        )
                     ],
                  ),
                ),
              );
            }
            // --- Случай 3: Данные успешно загружены ---
            else if (snapshot.hasData) {
              final posts = snapshot.data!; // Получаем список постов

              // Если список постов пуст
              if (posts.isEmpty) {
                 return Center(child: Text('Новостей пока нет.'));
              }

              // Отображаем список постов
              return ListView.builder(
                padding: EdgeInsets.all(8.0), // Отступы для всего списка
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return NewsCard(post: posts[index]); // Используем виджет карточки
                },
              );
            }
            // --- Случай 4: Неизвестное состояние (не должно происходить) ---
            else {
              return Center(child: Text('Что-то пошло не так...'));
            }
          },
        ),
      ),
    );
  }
}