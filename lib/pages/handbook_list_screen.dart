import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'handbook_view_screen.dart';
import 'handbook_create_screen.dart';
import '../l10n/app_localizations.dart';
import '../data/text_emojis.dart';
import '../services/settings_service.dart';

class HandbookListScreen extends StatefulWidget {
  const HandbookListScreen({super.key});

  @override
  State<HandbookListScreen> createState() =>
      _HandbookListScreenState();
}

class _HandbookListScreenState extends State<HandbookListScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Set<String> _selectedTags = {};
  final Set<String> _selectedPrimaryTags = {};
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  late final ScrollController _scrollController;
  bool _isFabVisible = true;
  List<String> _favoriteTags = [];

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
    _favoriteTags = settingsService.favoriteHandbookTagsNotifier.value;
    _selectedPrimaryTags.addAll(_favoriteTags);
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
    settingsService.favoriteHandbookTagsNotifier.addListener(_onFavoritesChanged);
  }
  void _onFavoritesChanged() {
  if (mounted) setState(() => _favoriteTags = settingsService.favoriteHandbookTagsNotifier.value);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    settingsService.favoriteHandbookTagsNotifier.removeListener(_onFavoritesChanged);
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
          _applyFilters();
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

            // Если не совпало с поиском, исключаем
            if (!searchMatch) return false;

            // Логика фильтрации по тегам
            final itemPrimaryTags = List<String>.from(f['primary_tags'] ?? []);
            final itemTags = List<String>.from(f['tags'] ?? []);

            // 1. Проверка по основным тегам
            final primaryTagMatch = _selectedPrimaryTags.isEmpty ||
                itemPrimaryTags.any((t) => _selectedPrimaryTags.contains(t));

            // Если не совпало по основным тегам, исключаем
            if (!primaryTagMatch) return false;

            // 2. Проверка по обычным тегам
            final tagMatch = _selectedTags.isEmpty ||
                itemTags.any((t) => _selectedTags.contains(t));

            // Если не совпало по обычным тегам, исключаем
            if (!tagMatch) return false;

            // Если все проверки пройдены, включаем элемент в результат
            return true;
          }).toList()
          ..sort((a, b) {
            return (a['title'] as String).compareTo(b['title'] as String);
          });
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
        appBar: AppBar(title: Text(l10n.handbookScreen)),
        body:_loading
          ? const Center(child: CircularProgressIndicator())
          : (_allItems.isEmpty)
          ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(getRandomEmoji(Sad), style: TextStyle(fontSize: 72, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(l10n.nothingFound, style: TextStyle(fontSize: 18, color: Colors.grey[400])),
            ],
          ))
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Сначала собираем все основные теги
                      final primaryTagsSet = <String>{};
                      for (var f in _allItems) {
                        final pt = List<dynamic>.from(f['primary_tags'] ?? []);
                        primaryTagsSet.addAll(pt.map((e) => e.toString()));
                      }
                      final primaryTagsList = primaryTagsSet.toList()..sort();

                      // Теперь собираем обычные теги в зависимости от выбранных основных
                      final tagsSet = <String>{};
                      if (_selectedPrimaryTags.isEmpty) {
                        // Если основные теги не выбраны, показываем все обычные теги
                        for (var f in _allItems) {
                          final t = List<dynamic>.from(f['tags'] ?? []);
                          tagsSet.addAll(t.map((e) => e.toString()));
                        }
                      } else {
                        // Иначе, показываем только те теги, которые есть в записях с выбранными основными тегами
                        final relatedItems = _allItems.where((item) => List<String>.from(item['primary_tags'] ?? []).any(_selectedPrimaryTags.contains));
                        for (var item in relatedItems) {
                          final t = List<dynamic>.from(item['tags'] ?? []);
                          tagsSet.addAll(t.map((e) => e.toString()));
                        }
                      }
                      final tagsList = tagsSet.toList()..sort();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (primaryTagsList.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: primaryTagsList.map((tag) {
                                  final isSelected = _selectedPrimaryTags.contains(tag);
                                  final isFavorite = _favoriteTags.contains(tag);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        final currentFavorites = List<String>.from(settingsService.favoriteHandbookTagsNotifier.value);
                                        final wasFavorite = currentFavorites.contains(tag);
                                        if (wasFavorite) {
                                          currentFavorites.remove(tag);
                                        } else {
                                          currentFavorites.add(tag);
                                        }
                                        settingsService.setFavoriteHandbookTags(currentFavorites);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(wasFavorite
                                            ? 'Тег удалён из избранных'
                                            : 'Тег добавлен в избранные'),
                                            duration: const Duration(seconds: 1),
                                          )
                                        );
                                      },
                                      child: FilterChip(
                                        label: Text(tag),
                                        avatar: isFavorite ? Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.primary) : null,
                                        selected: isSelected,
                                        onSelected: (v) {
                                          setState(() {
                                            if (v) {
                                              _selectedPrimaryTags.add(tag);
                                            } else {
                                              _selectedPrimaryTags.remove(tag);
                                            }
                                          });
                                          _applyFilters();
                                        }
                                      )
                                    )
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
                child: RefreshIndicator(
                  onRefresh: _loadHandbook,
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
                      // Карточка записи
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
                                    textStyle: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Описание (2 строки если это формула, если определение - 3)
                              Text(
                                f['description'] ?? '',
                                maxLines: f['type'] == 'formula' ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Оборачиваем все теги в один Wrap, чтобы избежать переполнения
                              Wrap(
                                spacing: 6.0,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Основные теги
                                  ...itemPrimaryTags.map(
                                    (t) => Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 12)),
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  // Обычные теги (первые 5)
                                  ...itemTags.take(5).map(
                                    (t) => Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 12)),
                                      visualDensity: VisualDensity.compact,
                                    ),
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
                ),
            ],
          ),
        // FAB для создания новой записи
        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2), // Сдвиг FAB'а при скролле вниз
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
