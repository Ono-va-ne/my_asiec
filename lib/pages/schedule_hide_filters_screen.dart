import 'package:flutter/material.dart';
import 'package:my_asiec/models/schedule_filter.dart';
import 'package:my_asiec/services/settings_service.dart';
import '../l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class ScheduleHideFiltersScreen extends StatefulWidget {
  const ScheduleHideFiltersScreen({super.key});

  @override
  State<ScheduleHideFiltersScreen> createState() =>
      _ScheduleHideFiltersScreenState();
}

class _ScheduleHideFiltersScreenState extends State<ScheduleHideFiltersScreen> {
  void _applyPreset(String presetType) {
    final filters = List<ScheduleFilter>.from(settingsService.scheduleFiltersNotifier.value);
    
    if (presetType == 'clear') {
      for (var f in filters) {
        f.isEnabled = false;
      }
    } else if (presetType == 'session') {
      final targetKeywords = ['зачёт', 'экзамен'];
      
      // Сначала выключаем всё лишнее, если нужно, или просто добавляем/включаем эти
      for (var f in filters) {
        if (targetKeywords.contains(f.keyword.toLowerCase())) {
          f.isEnabled = true;
        } else {
          f.isEnabled = false;
        }
      }
      
      // Добавляем отсутствующие
      for (var kw in targetKeywords) {
        if (!filters.any((f) => f.keyword.toLowerCase() == kw)) {
          filters.add(ScheduleFilter(
            id: const Uuid().v4(),
            keyword: kw[0].toUpperCase() + kw.substring(1),
            type: 'lesson',
            isBuiltIn: false,
            isEnabled: true,
          ));
        }
      }
    }

    // Обновляем значение в нотификаторе, это вызовет перестроение UI
    settingsService.scheduleFiltersNotifier.value = filters;
    // Сохраняем в SharedPreferences
    settingsService.saveScheduleFilters();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.presetApplied), duration: const Duration(seconds: 1)),
      );
    }
  }

  void _addNewFilter() {
    final textController = TextEditingController();
    // По умолчанию тип фильтра - 'lesson'
    String selectedType = 'lesson'; 
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.filterCreate),
          content:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.filterKeyword, // Ключевое слово
                    hintText: 'например, История',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.filterCreateTip,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text('Тип фильтра:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                // Используем StatefulBuilder, чтобы обновлять только чипсы внутри диалога
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Wrap(
                      spacing: 8.0,
                      children: [
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.discipline), // Дисциплина
                          selected: selectedType == 'lesson',
                          onSelected: (selected) => setDialogState(() => selectedType = 'lesson'),
                        ),
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.teacher), // Преподаватель
                          selected: selectedType == 'teacher',
                          onSelected: (selected) => setDialogState(() => selectedType = 'teacher'),
                        ),
                        ChoiceChip(
                          label: Text(AppLocalizations.of(context)!.room), // Аудитория
                          selected: selectedType == 'room',
                          onSelected: (selected) => setDialogState(() => selectedType = 'room'),
                        ),
                      ],
                    );
                  }
                ),

              ],
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                final keyword = textController.text.trim();
                if (keyword.isNotEmpty) {
                  final newFilter = ScheduleFilter(
                    id: const Uuid().v4(),
                    keyword: keyword,
                    type: selectedType, // Используем выбранный тип
                    isBuiltIn: false,
                    isEnabled: true,
                  );
                  settingsService.addScheduleFilter(newFilter);
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильтры'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'Подсказка',
            onPressed: () {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: const Text('Подсказка'),
                  content: const Text('Здесь можно настроить отображение пар. Если все фильтры выключены, отображаются все пары.'),
                  actions: <Widget>[TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('Понятно'))]
                );
              },
              );
            }
          )
        ],
      ),
      body: ValueListenableBuilder<List<ScheduleFilter>>(
        valueListenable: settingsService.scheduleFiltersNotifier,
        builder: (context, filters, _) {
          final builtInFilters = filters.where((f) => f.isBuiltIn).toList();
          final customFilters = filters.where((f) => !f.isBuiltIn).toList();
          // TODO: Исправить удаление фильтров
          return ListView(
            children: [
              // TODO: Добавить возможность создавать кастомные пресеты и настраивать их
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.layers_clear, size: 18),
                      label: const Text('Сбросить'),
                      onPressed: () => _applyPreset('clear'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.book, size: 18),
                      label: const Text('Сессия'),
                      onPressed: () => _applyPreset('session'),
                    ),
                  ],
                ),
              ),
              // if (builtInFilters.isNotEmpty) ...[
              //   const Padding(
              //     padding: EdgeInsets.all(16.0),
              //     child: Text('Встроенные фильтры',
              //         style: TextStyle(
              //             fontSize: 16, fontWeight: FontWeight.bold)),
              //   ),
              //   ...builtInFilters.map((filter) => SwitchListTile(
              //         title: Text(filter.keyword),
              //         value: filter.isEnabled,
              //         onChanged: (value) {
              //           setState(() {
              //             filter.isEnabled = value;
              //           });
              //           settingsService.updateScheduleFilter(filter);
              //         },
              //       )),
              //   const Divider(),
              // ],
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Пользовательские фильтры',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (customFilters.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('У вас пока нет фильтров.', style: TextStyle(color: Colors.grey)),
                ),
              ...customFilters.map((filter) => ListTile(
                    title: Text(filter.keyword),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: filter.isEnabled,
                          onChanged: (value) {
                            setState(() {
                              filter.isEnabled = value;
                            });
                            settingsService.updateScheduleFilter(filter);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            settingsService.deleteScheduleFilter(filter.id);
                          },
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewFilter,
        child: const Icon(Icons.add),
        tooltip: AppLocalizations.of(context)!.filterCreate,
      ),
    );
  }
}
