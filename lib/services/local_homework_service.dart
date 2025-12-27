import 'package:hive/hive.dart'; // Импортируем Hive
import 'package:uuid/uuid.dart'; // Импортируем пакет Uuid для генерации уникальных ID
import 'package:rxdart/rxdart.dart';
import '../models/homework.dart'; // Импортируем нашу модель Homework

class LocalHomeworkService {
  // Uuid - для генерации уникальных ID для локальных записей
  final _uuid = const Uuid();

  // Получаем "ящик" с локальными домашними заданиями
  // Убедись, что 'localHomeworkBox' - это то же имя, что ты использовал в main.dart
  final _homeworkBox = Hive.box<Homework>(
    'localHomeworkBox',
  ); // <--- Получаем открытый Box

  // --- Метод для получения ПОТОКА локальных домашних заданий ---
  // Возвращает Stream, который будет присылать обновления при изменениях в Box
  Stream<List<Homework>> getHomeworkStream() {
    print('LocalHomeworkService: getHomeworkService() вызван.');
    // box.watchFromDisk() возвращает Stream<BoxEvent>
    // .map((event) => _homeworkBox.values.toList()) преобразует BoxEvent в список всех объектов в Box
    // .startWith(_homeworkBox.values.toList()) гарантирует, что Stream сразу выдаст текущее состояние Box при подписке
    final stream = _homeworkBox.watch().map((event) {
      final homeworkList = _homeworkBox.values.toList();
      print(
        'LocalHomeworkService: watch().map() обработал событие BoxEvent. В Box-е ${homeworkList.length} элементов.',
      ); // Лог обработки события и кол-ва локальных ДЗ
      return homeworkList;
    });
    print(
      'LocalHomeworkService: Применяем startWith...',
    ); // Лог перед startWith
    final initialList = _homeworkBox.values.toList();
    print(
      'LocalHomeworkService: Начальный список локальных ДЗ для startWith: ${initialList.length} элементов.',
    ); // Лог начального значения
    return stream.startWith(initialList);
  }

  // --- Метод для добавления нового локального домашнего задания ---
  Future<void> addHomework(Homework homework) async {
    // Генерируем уникальный ID для локальной записи
    final localId = _uuid.v4(); // v4() генерирует случайный UUID

    // Создаем новую запись с сгенерированным ID и помечаем как локальную
    final localHomework = Homework(
      id: localId, // <--- Присваиваем сгенерированный ID
      discipline: homework.discipline,
      groupId: homework.groupId,
      group: homework.group,
      subgroup: homework.subgroup,
      task: homework.task,
      dueDate: homework.dueDate,
      photoUrls: homework.photoUrls,
      dateAdded: homework.dateAdded,
      isLocal: true, // <--- Явно помечаем как локальную!
    );

    // Добавляем объект в Box, используя сгенерированный ID как ключ
    await _homeworkBox.put(
      localId,
      localHomework,
    ); // <--- put(key, value) сохраняет объект с ключом
    print('Локальное ДЗ с ID $localId добавлено в Hive!');
  }

  // --- Метод для обновления существующего локального домашнего задания ---
  Future<void> updateHomework(Homework homework) async {
    // Проверяем, что у домашнего задания есть ID (ключ в Box)
    if (homework.id != null) {
      // Обновляем объект в Box по его ключу (ID)
      await _homeworkBox.put(
        homework.id!,
        homework,
      ); // <--- put(key, value) обновит объект, если ключ уже существует
      print('Локальное ДЗ с ID ${homework.id} обновлено в Hive!');
    } else {
      print('Ошибка: Невозможно обновить локальное ДЗ без ID!');
    }
  }

  // --- Метод для удаления локального домашнего задания ---
  Future<void> deleteHomework(String homeworkId) async {
    print(
      '  Внутри LocalHomeworkService.deleteHomework для ID: $homeworkId',
    ); // Отладка: внутри сервиса

    // Убедимся, что Box открыт (хотя он уже должен быть открыт в main)
    if (!_homeworkBox.isOpen) {
      print(
        '  Предупреждение: Box не открыт в deleteHomework. Открываем...',
      ); // Отладка: Box не открыт
      await Hive.openBox<Homework>(
        'localHomeworkBox',
      ); // Открываем, если закрыт
    }

    // Проверяем, существует ли элемент с таким ID в Box перед удалением (опционально)
    final exists = _homeworkBox.containsKey(homeworkId);
    print('  Элемент с ID $homeworkId существует в Box: $exists');

    await _homeworkBox.delete(homeworkId); // <--- КЛЮЧЕВАЯ СТРОКА для удаления!
    print(
      '  _homeworkBox.delete($homeworkId) выполнен.',
    ); // Отладка: команда удаления выполнена

    print(
      'Локальное ДЗ с ID $homeworkId удалено из Hive!',
    ); // Итоговое сообщение
  }

  // TODO: Добавить метод для получения одного локального ДЗ по ID, если понадобится
}
