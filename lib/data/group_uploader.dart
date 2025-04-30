import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/groups.dart'; // Импортируем файл с данными групп

class GroupDataUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadGroups() async {
    try {
      // 1. Получаем все документы из коллекции 'groups'
      final querySnapshot = await _firestore.collection('groups').get();

      // 2. Создаем Set с ID групп из groups.dart
      final Set<String> validGroupIds =
          availableGroupsData.map((group) => group.id).toSet();

      // 3. Проверяем и удаляем документы, ID которых нет в validGroupIds
      for (final doc in querySnapshot.docs) {
        if (!validGroupIds.contains(doc.id)) {
          print('Удаляем группу с ID ${doc.id}, так как ее нет в groups.dart');
          await doc.reference.delete();
        }
      }

      // 4. Загружаем или обновляем данные из availableGroupsData
      for (final group in availableGroupsData) {
        // Проверяем, существует ли уже документ с таким ID
        final docRef = _firestore.collection('groups').doc(group.id);
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          // Если документ существует, обновляем его
          await docRef.update({
            'name': group.name,
          });
          print('Группа ${group.name} с ID ${group.id} обновлена.');
        } else {
          // Если документ не существует, создаем его
          await docRef.set({
            'name': group.name,
          });
          print('Группа ${group.name} с ID ${group.id} добавлена.');
        }
      }
      print('Все группы успешно обработаны в Firestore.');
    } catch (e) {
      print('Ошибка при обработке групп в Firestore: $e');
    }
  }
}

// Пример использования (можно добавить в main.dart или в отдельный файл)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Убедитесь, что Firebase инициализирован
  // FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true); // Включаем кэширование Firestore
  // Инициализация Firebase должна быть выше

  final uploader = GroupDataUploader();
  await uploader.uploadGroups();
}
