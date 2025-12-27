import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class CreateFormulaScreen extends StatefulWidget {
  final String specialtyId;
  const CreateFormulaScreen({super.key, required this.specialtyId});

  @override
  State<CreateFormulaScreen> createState() => _CreateFormulaScreenState();
}

class _CreateFormulaScreenState extends State<CreateFormulaScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _formulaController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _formulaController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    try {
      final tags =
          _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final payload = {
        'title': _titleController.text.trim(),
        'formula': _formulaController.text.trim(),
        'summary': _summaryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': _imageController.text.trim(),
        'tags': tags,
        // Optionally include the authenticated user's id so row-level
        // security policies can verify ownership (if your table has
        // e.g. a `created_by` column).
        'spec_id': widget.specialtyId,
      };

      await _client.from('formulas').insert(payload);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
        print('Ошибка: $e');
    } finally {
      if (mounted)
        setState(() {
          _saving = false;
        });
    }
  }

  void _openLatexEditor() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController editorController = TextEditingController(text: _formulaController.text);
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('LaTeX редактор'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editorController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: r'Введите LaTeX, например: x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}' ,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  const Align(alignment: Alignment.centerLeft, child: Text('Предпросмотр:')),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).cardColor,
                      child: Builder(builder: (_) {
                        try {
                          return Math.tex(editorController.text, textStyle: const TextStyle(fontSize: 20));
                        } catch (e) {
                          return Text('Ошибка рендеринга: $e');
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
              ElevatedButton(
                onPressed: () {
                  _formulaController.text = editorController.text;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Применить'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать формулу')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название'),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Введите название'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _formulaController,
                decoration: const InputDecoration(
                  labelText: 'Формула (LaTeX или текст)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openLatexEditor,
                    icon: const Icon(Icons.open_in_full),
                    label: const Text('Открыть редактор LaTeX'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Container()),
                ],
              ),
              const SizedBox(height: 12),
              // Live preview
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Предпросмотр LaTeX:', style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Builder(builder: (_) {
                  try {
                    return Math.tex(_formulaController.text, textStyle: const TextStyle(fontSize: 18));
                  } catch (e) {
                    return Text('Ошибка рендеринга: $e');
                  }
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Краткое описание',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Полное описание'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'URL изображения (опционально)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Теги (через запятую)',
                ),
              ),
              const SizedBox(height: 20),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _save,
                    child: const Text('Сохранить'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
