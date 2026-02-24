import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'handbook_view_screen.dart';
import 'create_formula_screen.dart';
import '../l10n/app_localizations.dart';

class HandbookBySpecialtyScreen extends StatefulWidget {
  final String specialtyId;
  final String specialtyName;
  const HandbookBySpecialtyScreen({
    super.key,
    required this.specialtyId,
    required this.specialtyName,
  });

  @override
  State<HandbookBySpecialtyScreen> createState() =>
      _HandbookBySpecialtyScreenState();
}

class _HandbookBySpecialtyScreenState extends State<HandbookBySpecialtyScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Set<String> _selectedTags = {};
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  Future<List<Map<String, dynamic>>> _fetchHandbook() async {
    final data = await _client
        .from('formulas')
        .select()
        .eq('spec_id', widget.specialtyId)
        .order('title');
    return List<Map<String, dynamic>>.from(data as List);
  }

  @override
  void initState() {
    super.initState();
    _loadHandbook();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHandbook() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    try {
      final data = await _fetchHandbook();
      if (mounted) {
        setState(() {
          _allItems = data;
          _filteredItems = List<Map<String, dynamic>>.from(_allItems);
        });
      }
    } catch (e) {
      // keep lists empty, error will be shown in UI
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      _filteredItems =
          _allItems.where((f) {
            // search match
            final title = (f['title'] ?? '').toString().toLowerCase();
            final summary = (f['summary'] ?? '').toString().toLowerCase();
            final description =
                (f['description'] ?? '').toString().toLowerCase();
            final formula = (f['formula'] ?? '').toString().toLowerCase();
            final searchMatch =
                q.isEmpty ||
                title.contains(q) ||
                summary.contains(q) ||
                description.contains(q) ||
                formula.contains(q);

            // Фильтр: если нет выбранных тегов, то отображаем всё
            if (_selectedTags.isEmpty) return searchMatch;
            final itemTags =
                List<dynamic>.from(
                  f['tags'] ?? [],
                ).map((e) => e.toString()).toSet();
            final tagMatch = itemTags.any((t) => _selectedTags.contains(t));
            return searchMatch && tagMatch;
          }).toList();
    });
  }

  Future<Set<String>> get allTags async {
    Set<String> tags = {};
    for (var formula in _allItems) {
      final t = List<dynamic>.from(formula['tags'] ?? []);
      tags.addAll(t.map((e) => e.toString()));
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.specialtyName)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : (_allItems.isEmpty)
              ? Center(child: Text(l10n.nothingFound))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.search,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  // Tag filter chips
                  if (_allItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Builder(
                        builder: (context) {
                          final tagsSet = <String>{};
                          for (var f in _allItems) {
                            final t = List<dynamic>.from(f['tags'] ?? []);
                            tagsSet.addAll(t.map((e) => e.toString()));
                          }
                          final tagsList = tagsSet.toList()..sort();
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  tagsList.map((tag) {
                                    final selected = _selectedTags.contains(
                                      tag,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: FilterChip(
                                        label: Text(tag),
                                        selected: selected,
                                        onSelected: (v) {
                                          setState(() {
                                            if (v) {
                                              _selectedTags.add(tag);
                                            } else {
                                              _selectedTags.remove(tag);
                                            }
                                          });
                                          _applyFilters();
                                        },
                                      ),
                                    );
                                  }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
    
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, i) {
                        final f = _filteredItems[i];
                        final itemTags =
                            List<dynamic>.from(
                              f['tags'] ?? [],
                            ).map((e) => e.toString()).toList();
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => HandbookViewScreen(
                                      title: f['title'] ?? '',
                                      formula: f['formula'] ?? '',
                                      description: f['description'] ?? '',
                                      imageUrl: f['image_url'] ?? '',
                                      latexHandbook: f['formula'] ?? '',
                                      tags: itemTags.join(', '),
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Math.tex(
                                    f['formula'] ?? '',
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    f['summary'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (itemTags.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children:
                                          itemTags
                                              .map(
                                                (t) => Chip(
                                                  label: Text(
                                                    t,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                              )
                                              .toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CreateHandbookScreen(specialtyId: widget.specialtyId),
            ),
          );
          if (created == true) {
            _loadHandbook();
          }
        },
      ),
    );
  }
}
