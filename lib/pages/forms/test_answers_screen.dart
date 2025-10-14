import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestAnswersListScreen extends StatelessWidget {
  final String testId;
  final List<dynamic> questions;

  const TestAnswersListScreen({
    super.key,
    required this.testId,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ответы других пользователей')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('answers')
            .where('testId', isEqualTo: testId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Нет ответов.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final data = docs[idx].data() as Map<String, dynamic>;
              final answers = data['answers'] as Map<String, dynamic>;
              final userId = data['userId'] ?? 'Неизвестно';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Пользователь: $userId', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...questions.asMap().entries.map((entry) {
                        final qIdx = entry.key;
                        final q = entry.value;
                        final answer = answers[qIdx.toString()];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q['questionText'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                              if (q['type'] == 'shortAnswer' || q['type'] == 'paragraph')
                                Text(answer?.toString() ?? '—'),
                              if (q['type'] == 'singleChoice' && q['options'] != null)
                                Text(
                                  answer != null && answer is int && q['options'].length > answer
                                      ? q['options'][answer]['text'] ?? '—'
                                      : '—',
                                ),
                              if (q['type'] == 'multipleChoice' && q['options'] != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (answer is List
                                      ? answer.map((i) => q['options'][i]['text'] ?? '—').toList()
                                      : []).map((txt) => Text(txt)).toList(),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}