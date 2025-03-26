import 'package:flutter/material.dart';
import 'schedule_entry.dart';

// Не забудь добавить класс ScheduleEntry из шага 1 сюда или импортировать его

class ScheduleCard extends StatelessWidget {
  final ScheduleEntry entry; // Данные для этой карточки

  const ScheduleCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card( // Используем виджет Card для красивого контейнера с тенью
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Отступы вокруг карточки
      shape: RoundedRectangleBorder( // Слегка скруглим углы
          borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2.0, // Небольшая тень
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Внутренние отступы в карточке
        child: Row( // Используем Row, чтобы разместить элементы в строку
          crossAxisAlignment: CrossAxisAlignment.start, // Выравниваем элементы по верху
          children: [
            // Левая часть: Название дисциплины и преподаватель
            Expanded( // Expanded заставляет этот столбец занять всё доступное место по ширине
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Выравниваем текст влево
                children: [
                  Text(
                    entry.discipline,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Жирный шрифт
                      fontSize: 16.0, // Размер шрифта побольше
                    ),
                  ),
                  SizedBox(height: 4.0), // Небольшой отступ между текстами
                  Text(
                    entry.teacher,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[700], // Цвет чуть потемнее серого
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 16.0), // Отступ между левой и правой частями

            // Правая часть: Время и место
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Выравниваем текст вправо
              children: [
                Text(
                  '${entry.startTime} - ${entry.endTime}', // Формируем строку времени
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500, // Немного жирнее обычного
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 4.0), // Отступ
                Text(
                  '${entry.building}\n${entry.room}', // Корпус и аудитория с переносом строки
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.right, // Выравниваем текст вправо
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}