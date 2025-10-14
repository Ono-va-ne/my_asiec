import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_answers_screen.dart';

class TestPassScreen extends StatefulWidget {
  final String testId;
  final Map<String, dynamic> testData;
  final String userId; // Передавайте userId из вашего auth-сервиса

  const TestPassScreen({
    super.key,
    required this.testId,
    required this.testData,
    required this.userId,
  });

  @override
  State<TestPassScreen> createState() => _TestPassScreenState();
}

class _TestPassScreenState extends State<TestPassScreen> {
  bool _alreadyPassed = false;
  List<dynamic> _questions = [];
  Map<int, dynamic> _answers = {};
  Map<String, dynamic>? _userAnswers; // Для хранения ответов пользователя

  @override
  void initState() {
    super.initState();
    _questions = widget.testData['questions'] ?? [];
    _checkIfPassed();
  }

  Future<void> _checkIfPassed() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('answers')
        .where('testId', isEqualTo: widget.testId)
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() {
        _alreadyPassed = true;
        _userAnswers = snapshot.docs.first.data()['answers'] as Map<String, dynamic>?;
      });
    }
  }


  void _submitAnswers() async {
    // Преобразуем ключи Map<int, dynamic> -> Map<String, dynamic>
    final answersToSend = _answers.map((key, value) => MapEntry(key.toString(), value));
    await FirebaseFirestore.instance.collection('answers').add({
      'testId': widget.testId,
      'userId': widget.userId,
      'answers': answersToSend,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      setState(() {
        _alreadyPassed = true;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ответы отправлены!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_alreadyPassed && _userAnswers != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ваши ответы'),
          actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestAnswersListScreen(
                    testId: widget.testId,
                    questions: _questions,
                  ),
                ),
              );
            },
          ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.testData['description'] != null)
              Text(widget.testData['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ..._questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;
              final answer = _userAnswers![idx.toString()];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['questionText'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Ваш ответ:', style: const TextStyle(fontWeight: FontWeight.w500)),
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
                ),
              );
            }),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testData['title'] ?? 'Тест'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestAnswersListScreen(
                    testId: widget.testId,
                    questions: _questions,
                  ),
                ),
              );
            },
          ),
          ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.testData['description'] != null)
            Text(widget.testData['description'], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ..._questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['questionText'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    // Пример для текстового ответа:
                    if (q['type'] == 'shortAnswer' || q['type'] == 'paragraph')
                      TextField(
                        onChanged: (val) => _answers[idx] = val,
                        decoration: const InputDecoration(labelText: 'Ваш ответ'),
                      ),
                    // Пример для выбора:
                    if (q['type'] == 'singleChoice' && q['options'] != null)
                      ...List.generate(q['options'].length, (optIdx) {
                        final opt = q['options'][optIdx];
                        return RadioListTile(
                          title: Text(opt['text'] ?? ''),
                          value: optIdx,
                          groupValue: _answers[idx],
                          onChanged: (val) => setState(() => _answers[idx] = val),
                        );
                      }),
                    if (q['type'] == 'multipleChoice' && q['options'] != null)
                      ...List.generate(q['options'].length, (optIdx) {
                        final opt = q['options'][optIdx];
                        return CheckboxListTile(
                          title: Text(opt['text'] ?? ''),
                          value: (_answers[idx] ?? <int>[]).contains(optIdx),
                          onChanged: (checked) {
                            setState(() {
                              final selected = (_answers[idx] ?? <int>[]).cast<int>();
                              if (checked == true) {
                                selected.add(optIdx);
                              } else {
                                selected.remove(optIdx);
                              }
                              _answers[idx] = selected;
                            });
                          },
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _answers.length == _questions.length ? _submitAnswers : null,
            child: const Text('Отправить'),
            // TODO: Вернуть пользователя обратно и вывести "Результаты отправлены"
          ),
        ],
      ),
    );
  }
}