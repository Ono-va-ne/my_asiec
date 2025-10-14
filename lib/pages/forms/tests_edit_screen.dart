import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/settings_service.dart';

/// Перечисление для типов вопросов.
enum QuestionType {
  multipleChoice, // Множественный выбор
  singleChoice,   // Один из списка
  shortAnswer,    // Короткий ответ (текстом)
  paragraph,      // Развернутый ответ (текстом)
}

/// Вспомогательная функция для отображения типа вопроса на русском языке.
String questionTypeToString(QuestionType type) {
  switch (type) {
    case QuestionType.multipleChoice:
      return 'Множественный выбор';
    case QuestionType.singleChoice:
      return 'Один из списка';
    case QuestionType.shortAnswer:
      return 'Короткий ответ';
    case QuestionType.paragraph:
      return 'Развернутый ответ';
    default:
      return '';
  }
}

/// Модель для варианта ответа в вопросах с выбором.
class Option {
  // Используем TextEditingController для управления текстом варианта.
  bool isCorrect = false;
  final TextEditingController textController = TextEditingController();

  Option({String text = '', this.isCorrect = false}) {
    textController.text = text;
  }

  /// Преобразует объект Option в JSON-совместимый Map.
  Map<String, dynamic> toJson() {
    return {
      'text': textController.text,
      'isCorrect': isCorrect,
    };
  }
}

/// Модель для одного вопроса.
class Question {
  final TextEditingController questionController = TextEditingController();
  QuestionType type;
  List<Option> options = [];

  Question({
    String questionText = '',
    this.type = QuestionType.singleChoice,
  }) {
    questionController.text = questionText;
    // По умолчанию добавляем один вариант ответа для вопросов с выбором.
    if (type == QuestionType.multipleChoice || type == QuestionType.singleChoice) {
      options.add(Option(text: ''));
    }
  }

  /// Преобразует объект Question в JSON-совместимый Map.
  Map<String, dynamic> toJson() {
    return {
      'questionText': questionController.text,
      'type': type.name, // Сохраняем enum как строку (e.g., 'singleChoice')
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

/// Основной экран для создания теста.
class TestCreationScreen extends StatefulWidget {
  const TestCreationScreen({super.key});

  @override
  State<TestCreationScreen> createState() => _TestCreationScreenState();
}

class _TestCreationScreenState extends State<TestCreationScreen> {
  final _testTitleController = TextEditingController(text: 'Новый тест');
  final _testDescriptionController = TextEditingController();
  final _testGroupController = TextEditingController();
  final List<Question> _questions = [];
  bool _isSaving = false;

  List<Map<String, dynamic>> _groups = [];
  String? _selectedGroupId;
  String? _selectedGroupName;

  @override
  void initState() {
    super.initState();
    final defaultGroupId = settingsService.getDefaultGroupId(); // Получаем ID из настроек
    if (defaultGroupId != null) {
      _selectedGroupId = defaultGroupId;
    }
    _fetchGroups();
    _addQuestion();
  }

  Future<void> _fetchGroups() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('groups').get();
      final groupsMap = <String, String>{};
      for (final doc in querySnapshot.docs) {
        groupsMap[doc.id] = doc.get('name');
      }
      final sortedGroups = groupsMap.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
      if (!mounted) return;
      setState(() {
        _groups = sortedGroups;
        if (_selectedGroupId != null) {
          try {
            _selectedGroupName = _groups.firstWhere((group) => group['id'] == _selectedGroupId)['name'];
          } catch (e) {
            _selectedGroupId = null;
            _selectedGroupName = null;
          }
        }
        // Если нет выбранной группы, выбираем первую из списка
        if (_selectedGroupId == null && _groups.isNotEmpty) {
          _selectedGroupId = _groups.first['id'];
          _selectedGroupName = _groups.first['name'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки групп: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Важно очищать контроллеры, чтобы избежать утечек памяти.
    _testTitleController.dispose();
    _testDescriptionController.dispose();
    for (var q in _questions) {
      q.questionController.dispose();
      for (var o in q.options) {
        o.textController.dispose();
      }
    }
    super.dispose();
  }

  /// Добавляет новый пустой вопрос в список.
  void _addQuestion() {
    setState(() {
      _questions.add(Question());
    });
  }

  /// Удаляет вопрос по индексу.
  void _removeQuestion(int index) {
    setState(() {
      // Очищаем контроллеры удаляемого вопроса
      final question = _questions[index];
      question.questionController.dispose();
      for (var option in question.options) {
        option.textController.dispose();
      }
      _questions.removeAt(index);
    });
  }

  /// Собирает все данные и сохраняет их в Cloud Firestore.
  Future<void> _saveTest() async {
    if (_isSaving) return;

    if (_testTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите название теста.')),
      );
      return;
    }
    if (_selectedGroupId == null || _selectedGroupName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите группу.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final testData = {
        'title': _testTitleController.text.trim(),
        'description': _testDescriptionController.text.trim(),
        'group': _selectedGroupName,
        'groupId': _selectedGroupId,
        'createdAt': FieldValue.serverTimestamp(), // Добавляем временную метку создания
        'questions': _questions.map((q) => q.toJson()).toList(),
      };

      // Сохраняем в коллекцию 'tests'
      await FirebaseFirestore.instance.collection('tests').add(testData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тест успешно сохранен в Firebase!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание теста'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ))
              : IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  onPressed: _saveTest,
                  tooltip: 'Сохранить тест',
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Заголовок и описание теста
          _buildTestHeader(),
          const SizedBox(height: 16),
          const Divider(thickness: 2),
          // Список виджетов-вопросов
          ListView.builder(
            shrinkWrap: true, // Важно для вложенных списков
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              return _QuestionCard(
                // Используем ValueKey, чтобы Flutter правильно обновлял виджеты при изменении порядка
                key: ValueKey(_questions[index]),
                question: _questions[index],
                onRemove: () => _removeQuestion(index),
                onTypeChanged: (newType) {
                  setState(() {
                    _questions[index].type = newType!;
                    // Очищаем варианты, если переключились на текстовый тип вопроса
                    if (newType != QuestionType.multipleChoice && newType != QuestionType.singleChoice) {
                      _questions[index].options.clear();
                    } else if (_questions[index].options.isEmpty) {
                      // Добавляем вариант по умолчанию, если переключились на вопрос с выбором
                      _questions[index].options.add(Option(text: ''));
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Добавить вопрос'),
      ),
    );
  }

  /// Виджет для редактирования названия и описания теста.
  Widget _buildTestHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _testTitleController,
              decoration: const InputDecoration(
                labelText: 'Название теста',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGroupName,
              decoration: const InputDecoration(labelText: 'Группа', border: OutlineInputBorder()),
              items: _groups.map((group) {
                return DropdownMenuItem<String>(
                  value: group['name'],
                  child: Text(group['name']),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGroupName = newValue;
                  _selectedGroupId = _groups.firstWhere((group) => group['name'] == newValue)['id'];
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, выберите группу';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _testDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет-карточка для одного вопроса.
class _QuestionCard extends StatefulWidget {
  final Question question;
  final VoidCallback onRemove;
  final ValueChanged<QuestionType?> onTypeChanged;

  const _QuestionCard({
    required super.key,
    required this.question,
    required this.onRemove,
    required this.onTypeChanged,
  });

  @override
  __QuestionCardState createState() => __QuestionCardState();
}

class __QuestionCardState extends State<_QuestionCard> {
  late final FocusNode _questionFocusNode;

  @override
  void initState() {
    super.initState();
    _questionFocusNode = FocusNode();
    _questionFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _questionFocusNode.removeListener(_onFocusChanged);
    _questionFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _addOption() {
    setState(() {
      widget.question.options.add(Option(text: ''));
    });
  }

  void _removeOption(int index) {
    setState(() {
      // Очищаем контроллер
      widget.question.options[index].textController.dispose();
      widget.question.options.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  TextFormField(
                    focusNode: _questionFocusNode,
                    controller: widget.question.questionController,
                    decoration: const InputDecoration(
                      labelText: 'Текст вопроса',
                      // contentPadding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                    ),
                  ),
            const SizedBox(height: 16),
                SizedBox(
                  child: DropdownButtonFormField<QuestionType>(
                    value: widget.question.type,
                    isExpanded: true,
                    onChanged: widget.onTypeChanged,
                    items: QuestionType.values.map((QuestionType type) {
                      return DropdownMenuItem<QuestionType>(
                        value: type,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(questionTypeToString(type), overflow: TextOverflow.ellipsis,),
                        ),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            _buildAnswerArea(),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.question.type == QuestionType.multipleChoice || widget.question.type == QuestionType.singleChoice)
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Добавить вариант'),
                    onPressed: _addOption,
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: widget.onRemove,
                  tooltip: 'Удалить вопрос',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Строит область для ответа в зависимости от типа вопроса.
  Widget _buildAnswerArea() {
    switch (widget.question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.singleChoice:
        return _buildOptionsList();
      case QuestionType.shortAnswer:
        return const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Поле для короткого ответа',
            border: UnderlineInputBorder(),
          ),
        );
      case QuestionType.paragraph:
        return const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Поле для развернутого ответа',
            border: UnderlineInputBorder(),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Строит редактируемый список вариантов ответа.
  Widget _buildOptionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.question.options.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                widget.question.type == QuestionType.singleChoice
                    ? widget.question.options[index].isCorrect
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off
                    : widget.question.options[index].isCorrect
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.question.options[index].textController,
                  decoration: InputDecoration(
                    hintText: 'Вариант ${index + 1}',
                  ),
                ),
              ),
              // Не даем удалить последний вариант
              if (widget.question.options.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => _removeOption(index),
                ),
            ],
          ),
          
        );
      },
    );
  }
}