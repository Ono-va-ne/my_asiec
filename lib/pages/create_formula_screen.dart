import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../l10n/app_localizations.dart';

class CreateHandbookScreen extends StatefulWidget {
  final String specialtyId;
  const CreateHandbookScreen({super.key, required this.specialtyId});

  @override
  State<CreateHandbookScreen> createState() => _CreateHandbookScreenState();
}

class _CreateHandbookScreenState extends State<CreateHandbookScreen> {
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
    _formulaController.removeListener(_onHandbookChanged);
    _formulaController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _formulaController.addListener(_onHandbookChanged);
  }

  void _onHandbookChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tags = _tagsController.text
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
        'spec_id': widget.specialtyId,
      };

      await _client.from('formulas').insert(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openLatexEditor() {
    Navigator.of(context)
        .push<String>(
      MaterialPageRoute(
        builder: (_) => FullscreenLatexEditor(initial: _formulaController.text),
        fullscreenDialog: true,
      ),
    )
        .then((res) {
      if (res != null) {
        setState(() => _formulaController.text = res);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.handbookCreate)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.handbookEnterName),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.handbookEnterName : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openLatexEditor,
                    icon: const Icon(Icons.functions),
                    label: Text(l10n.handbookOpenLatexEditor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Container()),
                ],
              ),
              // const SizedBox(height: 8),
              // _snippetButtons(_formulaController),
              const SizedBox(height: 12),
              // Live preview
              Align(
                alignment: Alignment.centerLeft,
                child: Text('${l10n.handbookFormula}:', style: Theme.of(context).textTheme.bodyMedium),
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
                    return Text('${l10n.error}: $e');
                  }
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                decoration: InputDecoration(labelText: l10n.handbookSummary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.handbookDescription),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(labelText: '${l10n.handbookPhotoURL} (${l10n.optional})'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(labelText: l10n.handbookTags),
              ),
              const SizedBox(height: 20),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _save, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }
}

class FullscreenLatexEditor extends StatefulWidget {
  final String initial;
  const FullscreenLatexEditor({super.key, required this.initial});

  @override
  State<FullscreenLatexEditor> createState() => _FullscreenLatexEditorState();
}

class _FullscreenLatexEditorState extends State<FullscreenLatexEditor> {
  late final TextEditingController _editorController;

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController(text: widget.initial);
    _editorController.addListener(_onEditorChanged);
  }

  @override
  void dispose() {
    _editorController.removeListener(_onEditorChanged);
    _editorController.dispose();
    super.dispose();
  }

  void _onEditorChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _insertSnippet(String snippet, [int cursorOffset = -1]) {
    final controller = _editorController;
    final sel = controller.selection;
    final base = (sel.isValid) ? sel.start : controller.text.length;
    final newText = controller.text.replaceRange(base, base, snippet);
    controller.text = newText;
    final offset = (cursorOffset >= 0) ? cursorOffset : snippet.length;
    final newPos = (base + offset).clamp(0, newText.length).toInt();
    controller.selection = TextSelection.collapsed(offset: newPos);
  }

  Widget _snippetButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(onPressed: () => _insertSnippet(r'\pi'), child: const Text('π')),
        OutlinedButton(onPressed: () => _insertSnippet(r'\sqrt{}', r'\sqrt{'.length), child: const Text('√')),
        OutlinedButton(onPressed: () => _insertSnippet(r'\frac{}{}', r'\frac{'.length), child: const Text('½')),
        OutlinedButton(onPressed: () => _insertSnippet(r'^{}', 2), child: const Text('x²')),
        OutlinedButton(onPressed: () => _insertSnippet(r'_{}', 2), child: const Text('x₂')),
        OutlinedButton(onPressed: () => _insertSnippet(r'\neq'), child: const Text('≠')),
        OutlinedButton(onPressed: () => _insertSnippet(r'\equiv'), child: const Text('≡')),
        OutlinedButton(onPressed: () => _insertSnippet(r'\in'), child: const Text('∈')),
        OutlinedButton(onPressed: () => _insertSnippet(r'\infty'), child: const Text('∞')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.handbookLatexEditor),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_editorController.text),
            child: Text(l10n.save, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return Column(
            children: [
              _snippetButtons(),
              const SizedBox(height: 8),
              Expanded(
                child: isNarrow
                    ? Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editorController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: l10n.handbookLatexHint,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Builder(builder: (_) {
                                  try {
                                    return Math.tex(_editorController.text,
                                        textStyle: const TextStyle(fontSize: 20));
                                  } catch (e) {
                                    return Text('${l10n.error}: $e');
                                  }
                                }),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editorController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: l10n.handbookLatexHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Builder(builder: (_) {
                                  try {
                                    return Math.tex(_editorController.text,
                                        textStyle: const TextStyle(fontSize: 20));
                                  } catch (e) {
                                    return Text('${l10n.error}: $e');
                                  }
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
