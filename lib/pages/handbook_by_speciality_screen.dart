import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'handbook_view_screen.dart';
import 'handbook_create_screen.dart';
import '../l10n/app_localizations.dart';
import '../data/text_emojis.dart';

class HandbookBySpecialtyScreen extends StatefulWidget {
  // final String specialtyId;
  // final String specialtyName;
  // const HandbookBySpecialtyScreen({
  //   super.key,
  //   required this.specialtyId,
  //   required this.specialtyName,
  // });

  @override
  State<HandbookBySpecialtyScreen> createState() =>
      _HandbookBySpecialtyScreenState();
}

class _HandbookBySpecialtyScreenState extends State<HandbookBySpecialtyScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Set<String> _selectedTags = {};
  final Set<String> _selectedPrimaryTags = {};
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  late final ScrollController _scrollController;
  bool _isFabVisible = true;

  Future<List<Map<String, dynamic>>> _fetchHandbook() async {
    final data = await _client
        .from('formulas')
        .select()
        // .eq('spec_id', widget.specialtyId)
        .order('title');
    return List<Map<String, dynamic>>.from(data as List);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadHandbook();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isFabVisible) {
          setState(() => _isFabVisible = false);
        }
      } else {
        if (!_isFabVisible) {
          setState(() => _isFabVisible = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
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
      // Фильтр карт
      _filteredItems =
          _allItems.where((f) {
            // search match
            final title = (f['title'] ?? '').toString().toLowerCase();
            final type = (f['type'] ?? '').toString().toLowerCase();
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
            if (_selectedTags.isEmpty && _selectedPrimaryTags.isEmpty) return searchMatch;
            final itemTags =
                List<dynamic>.from(
                  f['tags'] ?? [],
                ).map((e) => e.toString()).toSet();
            final itemPrimaryTags =
                List<dynamic>.from(
                  f['primary_tags'] ?? [],
                ).map((e) => e.toString()).toSet();
            final tagMatch = itemTags.any((t) => _selectedTags.contains(t)) || itemPrimaryTags.any((t) => _selectedPrimaryTags.contains(t));
            return searchMatch && tagMatch;
          }).toList();
    });
  }

  Future<Set<String>> get allTags async {
    Set<String> tags = {};
    Set<String> primaryTags = {};
    for (var formula in _allItems) {
      final t = List<dynamic>.from(formula['tags'] ?? []);
      final pt = List<dynamic>.from(formula['primary_tags'] ?? []);
      tags.addAll(t.map((e) => e.toString()));
      primaryTags.addAll(pt.map((e) => e.toString()));
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(title: Text(widget.specialtyName)),
        body:_loading
          ? const Center(child: CircularProgressIndicator())
          : (_allItems.isEmpty)
          ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(getRandomEmoji(), style: TextStyle(fontSize: 72, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(l10n.nothingFound, style: TextStyle(fontSize: 18, color: Colors.grey[400])),
            ],
          ))
          : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                // Поиск (ищет в названии и описании)
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
                      final primaryTagsSet = <String>{};
                      for (var f in _allItems) {
                        final t = List<dynamic>.from(f['tags'] ?? []);
                        final pt = List<dynamic>.from(f['primary_tags'] ?? []);
                        tagsSet.addAll(t.map((e) => e.toString()));
                        primaryTagsSet.addAll(pt.map((e) => e.toString()));
                      }
                      final tagsList = tagsSet.toList()..sort();
                      final primaryTagsList = primaryTagsSet.toList()..sort();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (primaryTagsList.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: primaryTagsList.map((tag) {
                                  final selected =
                                      _selectedPrimaryTags.contains(tag);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(tag),
                                      selected: selected,
                                      onSelected: (v) {
                                        setState(() {
                                          if (v) {
                                            _selectedPrimaryTags.add(tag);
                                          } else {
                                            _selectedPrimaryTags.remove(tag);
                                          }
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (tagsList.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: tagsList.map((tag) {
                                  final selected = _selectedTags.contains(tag);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
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
                            ),
                        ],
                      );
                    },
                  ),
                ),
      
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  controller: _scrollController,
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, i) {
                    final f = _filteredItems[i];
                    final itemTags =
                        List<dynamic>.from(
                          f['tags'] ?? [],
                        ).map((e) => e.toString()).toList();
                    final itemPrimaryTags =
                        List<dynamic>.from(
                          f['primary_tags'] ?? [],
                        ).map((e) => e.toString()).toList();
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => HandbookViewScreen(
                                  title: f['title'] ?? '',
                                  type: f['type'] ?? '',
                                  formula: f['formula'] ?? '',
                                  description: f['description'] ?? '',
                                  imageUrl: f['image_url'] ?? '',
                                  latexHandbook: f['formula'] ?? '',
                                  tags: itemTags.join(', '),
                                  primaryTags: itemPrimaryTags.join(''),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Название (врапнутый в Expanded чтобы не было overflow)
                                  Expanded(
                                    child: Text(
                                      f['title'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Иконка типа записи
                                  if (f['type'] == 'formula')
                                    Icon(Icons.functions, color: Theme.of(context).colorScheme.primary, semanticLabel: 'Formula',)
                                  else
                                    Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
                                ],
                              ),
                              // Формула (если тип записи 'formula')
                              if (f['type'] == 'formula')
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Math.tex(
                                    f['formula'] ?? '',
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Описание (2 строки если это формула, в остальных случаях (определение) - 3)
                              Text(
                                f['description'] ?? '',
                                maxLines: f['type'] == 'formula' ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Ряд тегов: сначала первичные (primary_tags), затем остальные (tags)
                              Row(
                                children: [
                                  // Primary tags
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: itemPrimaryTags.map(
                                      (t) => Chip(
                                        label: Text(t, style: const TextStyle(fontSize: 12)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ).toList(),
                                  ),
                                  Container(height: 20, width: 1, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 6)),
                                  // Tags (if any)
                                  if (itemTags.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: itemTags.map(
                                        (t) => Chip(
                                          label: Text(t, style: const TextStyle(fontSize: 12)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ).toList(),
                                    ),
                                ],
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
        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HandbookCreateScreen(specialtyId: '1'),
                ),
              );
              if (created == true) {
                _loadHandbook();
              }
            },
          ),
        ),
      ),
    );
  }
}
