import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tests_edit_screen.dart';
import 'test_pass_screen.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Все тесты')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tests').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Тесты не найдены.'));
          }
          final tests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index].data() as Map<String, dynamic>;
              final title = test['title'] ?? 'Без названия';
              final group = test['group'] ?? 'Без группы';
              final questions = (test['questions'] as List?)?.length ?? 0;
              final dueDate = test['dueDate'] != null
                  ? (test['dueDate'] as Timestamp).toDate()
                  : null;
              final discipline = test['discipline'] ?? 'Без предмета';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Группа: $group'),
                      Text('Предмет: $discipline'),
                      Text('Вопросов: $questions'),
                      if (dueDate != null)
                        Text('Срок сдачи: ${_formatDate(dueDate)}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestPassScreen(
                          testId: tests[index].id,
                          testData: test,
                          userId: 'VA', // Получите userId из вашего auth-сервиса
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TestCreationScreen()),
          );
          },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}