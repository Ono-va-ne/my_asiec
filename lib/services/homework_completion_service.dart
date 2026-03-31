import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeworkCompletionService {
  static const _boxName = 'completedHomeworkBox';
  late Box<bool> _completedBox;

  // ValueNotifier для уведомления UI об изменениях
  final ValueNotifier<Set<String>> completedIdsNotifier = ValueNotifier<Set<String>>({});
  final ValueNotifier<int> overdueCountNotifier = ValueNotifier(0);

  Future<void> init() async {
    _completedBox = await Hive.openBox<bool>(_boxName);
    _loadCompletedIds();
  }

  void _loadCompletedIds() {
    final completedIds = _completedBox.keys.cast<String>().toSet();
    completedIdsNotifier.value = completedIds;
  }

  bool isCompleted(String homeworkId) {
    return _completedBox.containsKey(homeworkId);
  }

  Future<void> toggleCompletionStatus(String homeworkId) async {
    if (isCompleted(homeworkId)) {
      await _completedBox.delete(homeworkId);
    } else {
      await _completedBox.put(homeworkId, true);
    }
    // Загружаем обновленный список и уведомляем слушателей
    _loadCompletedIds();
  }

  Set<String> getCompletedIds() {
    return _completedBox.keys.cast<String>().toSet();
  }

  void updateOverdueCount(int count) {
    if (overdueCountNotifier.value != count) {
      overdueCountNotifier.value = count;
    }
  }

  void dispose() {
    completedIdsNotifier.dispose();
    overdueCountNotifier.dispose();
    // _completedBox.close(); // Не закрываем, так как Hive управляет этим
  }
}

// Глобальный экземпляр сервиса
final homeworkCompletionService = HomeworkCompletionService();