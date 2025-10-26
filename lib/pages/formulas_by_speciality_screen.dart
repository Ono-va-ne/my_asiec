import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'formula_view_screen.dart';

class FormulasBySpecialtyScreen extends StatefulWidget {
  final String specialtyId;
  final String specialtyName;
  const FormulasBySpecialtyScreen({super.key, required this.specialtyId, required this.specialtyName});

  @override
  State<FormulasBySpecialtyScreen> createState() => _FormulasBySpecialtyScreenState();
}

class _FormulasBySpecialtyScreenState extends State<FormulasBySpecialtyScreen> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  Future<List<Map<String, dynamic>>> _fetchFormulas() async {
    final data = await _client.from('formulas').select().eq('spec_id', widget.specialtyId).order('title');
    return List<Map<String, dynamic>>.from(data as List);
  }

  @override
  void initState() {
    super.initState();
    _future = _fetchFormulas();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.specialtyName)),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Ошибка: ${snap.error}'));
            final items = snap.data ?? [];
            if (items.isEmpty) return const Center(child: Text('Формулы не найдены'));
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final f = items[i];
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FormulaViewScreen(
                        title: f['title'] ?? '',
                        formula: f['formula'] ?? '',
                        description: f['description'] ?? '',
                        imageUrl: f['image_url'] ?? '',
                        latexFormula: f['formula'] ?? '',
                      ),
                    ));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title']!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Math.tex(f['formula'], textStyle: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),                        
                          Text(
                            f['summary']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          // title: Text(f['title'] ?? ''),
                          // subtitle: Text(f['summary'] ?? ''),
                          // trailing: (f['tags'] != null) ? Wrap(
                          //   spacing: 6,
                          //   children: (List<dynamic>.from(f['tags'] ?? [])).map((t) => Chip(label: Text(t.toString()))).toList(),
                          // ) : null,
                        ]
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}