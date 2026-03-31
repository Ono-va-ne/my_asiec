import 'package:flutter/material.dart';
import 'package:my_asiec/models/teacher_info.dart';
import 'package:dynamic_app_icon_flutter_plus/dynamic_app_icon_flutter_plus.dart';
import '../services/settings_service.dart'; // Импортируем сервис
import '../data/groups.dart'; // Импортируем список групп (fallback)
import '../services/groups_service.dart';
import '../services/teachers_service.dart';
import '../models/group_info.dart';
import '../data/teachers.dart';
import '../data/rooms.dart'; // Импортируем список аудиторий
import '../l10n/app_localizations.dart';
// import '../models/group_info.dart'; // Импортируем модель группы


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedGroupId; // Храним ID выбранной группы по умолчанию
  String? _selectedTeacherId;
  String? _selectedRoomId;
  String? _currentIconName;
  final _groupsService = GroupsService();
  List<GroupInfo> _supabaseGroups = [];
  List<TeacherInfo> _supabaseTeachers = [];
  final _teachersService = TeachersService();

  // Инициализируем с пустыми значениями
  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadCurrentIcon();
    _loadAllIcons();
    _loadTeachers();
    // Загружаем текущую выбранную группу при инициализации
    _selectedGroupId = settingsService.getDefaultGroupId();
    _selectedTeacherId = settingsService.getDefaultTeacherId();
    _selectedRoomId = settingsService.getDefaultRoomId();
    // Мы не используем ValueListenableBuilder здесь, т.к. нам не нужно
    // динамически перестраивать весь экран при смене группы,
    // достаточно обновить Dropdown при выборе.
  }

  Future<void> _loadCurrentIcon() async {
    String? iconName = await DynamicAppIconFlutterPlus.getAlternateIconName();

    // Если выбрана иконка 'flow', но сейчас не октябрь, сбрасываем на стандартную
    if (iconName == 'barracuda' && !(DateTime.now().month == 10)) {
      await DynamicAppIconFlutterPlus.setAlternateIconName(null);
      iconName = null; // Обновляем локальное состояние
    }
    if (mounted) {
      // Устанавливаем иконку в состояние виджета
      setState(() => _currentIconName = iconName);
    }
  }
  Future<void> _loadAllIcons() async {
    List<String> availableIcons = await DynamicAppIconFlutterPlus.getAvailableIcons();
    print('Available icons: $availableIcons');
    // Output: Available icons: [dark, light]
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupsService.getGroups();
      if (mounted) setState(() => _supabaseGroups = groups);
    } catch (e) {
      print('Ошибка загрузки групп из Supabase: $e');
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers = await _teachersService.getTeachers();
      if (mounted) setState(() => _supabaseTeachers = teachers);
    } catch (e) {
      print('Ошибка загрузки преподавателей из Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // --- Секция: Группа по умолчанию ---
          _buildSectionHeader(l10n.scheduleScreen),
          ListTile(
            leading: Icon(Icons.group_outlined),
            title: Text(l10n.group),
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  // Используем ID группы как значение
                  value: _selectedGroupId,
                  hint: Text(l10n.settingNotSelected),
                  // Фильтруем список, чтобы не было ошибки, если сохраненный ID невалиден
                  items: (_supabaseGroups.isNotEmpty ? _supabaseGroups : availableGroupsData)
                      .map((group) => DropdownMenuItem<String>(
                            value: group.id,
                            child: Text(group.name),
                          ))
                      .toList(),
                  onChanged: (String? newGroupId) {
                    if (newGroupId != null) {
                      setState(() {
                        _selectedGroupId = newGroupId; // Обновляем UI
                      });
                      settingsService.setDefaultGroupId(
                        newGroupId,
                      ); // Сохраняем настройку
                    }
                  },
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outlined),
            title: Text(l10n.teacher),
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  // Используем ID группы как значение
                  value: _selectedTeacherId,
                  hint: Text(l10n.settingNotSelected),
                  // Фильтруем список, чтобы не было ошибки, если сохраненный ID невалиден
                  items: (_supabaseTeachers.isNotEmpty ? _supabaseTeachers : availableTeachersData)
                      .map((teacher) => DropdownMenuItem<String>(
                            value: teacher.id,
                            child: Text(
                              teacher.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ))
                      .toList(),
                  onChanged: (String? newTeacherId) {
                    if (newTeacherId != null) {
                      setState(() {
                        _selectedTeacherId = newTeacherId; // Обновляем UI
                      });
                      settingsService.setDefaultTeacherId(
                        newTeacherId,
                      ); // Сохраняем настройку
                    }
                  },
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.room_outlined),
            title: Text(l10n.room),
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  // Используем ID группы как значение
                  value: _selectedRoomId,
                  hint: Text(l10n.settingNotSelected),
                  // Фильтруем список, чтобы не было ошибки, если сохраненный ID невалиден
                  items:
                      availableRoomsData
                          .map(
                            (room) => DropdownMenuItem<String>(
                              value: room.id,
                              child: Text(
                                room.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (String? newRoomId) {
                    if (newRoomId != null) {
                      setState(() {
                        _selectedRoomId = newRoomId; // Обновляем UI
                      });
                      settingsService.setDefaultRoomId(
                        newRoomId,
                      ); // Сохраняем настройку
                    }
                  },
                ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settingsService.showBreaksInScheduleNotifier,
            builder: (context, isBreaksEnabled, _) {
              return SwitchListTile(
                secondary: Icon(Icons.free_breakfast_outlined),
                title: Text(l10n.settingShowBreaks),
                value: isBreaksEnabled,
                onChanged: (bool enabled) {
                  settingsService.setShowBreaksInSchedule(enabled);
                },
              );
            },
          ),

          Divider(),

          // --- Секция: Тема ---
          _buildSectionHeader(l10n.settingAppearance),
          // Выбор режима темы
          ValueListenableBuilder<ThemeMode>(
            valueListenable: settingsService.themeModeNotifier,
            builder: (context, currentMode, _) {
              return ListTile(
                leading: Icon(Icons.brightness_6_outlined),
                title: Text(l10n.settingTheme),
                trailing: DropdownButton<ThemeMode>(
                  value: currentMode,
                  underline: SizedBox.shrink(), // Убираем подчеркивание
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.settingSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.settingThemeLight),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.settingThemeDark),
                    ),
                  ],
                  onChanged: (ThemeMode? newMode) {
                    if (newMode != null) {
                      settingsService.setThemeMode(
                        newMode,
                      ); // Сохраняем и уведомляем
                    }
                  },
                ),
              );
            },
          ),
          // Material You (Dynamic Color) - доступно только на Android 12+
          // Можно добавить проверку платформы и версии ОС, если нужно
          ValueListenableBuilder<bool>(
            valueListenable: settingsService.materialYouNotifier,
            builder: (context, isMaterialYouEnabled, _) {
              return SwitchListTile(
                secondary: Icon(Icons.color_lens_outlined),
                title: Text(l10n.settingThemeMaterialYou),
                subtitle: Text(l10n.settingThemeMaterialYouDescription),
                value: isMaterialYouEnabled,
                onChanged: (bool enabled) {
                  settingsService.setMaterialYou(enabled);
                },
              );
            },
          ),
          Divider(),
          _buildSectionHeader(l10n.settingLanguage),
          ValueListenableBuilder<Locale?>(
            valueListenable: settingsService.localeNotifier,
            builder: (context, currentLocale, _) {
              return ListTile(
                leading: Icon(Icons.language_outlined),
                title: Text(l10n.settingLanguage),
                trailing: DropdownButton<String?>(
                  value: currentLocale?.languageCode,
                  hint: Text(l10n.settingSystem),
                  underline: SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: null, // null для системного языка
                      child: Text(l10n.settingSystem),
                    ),
                    DropdownMenuItem(
                      value: 'ru',
                      child: Text("Русский"),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text("English"),
                    ),
                  ],
                  onChanged: (String? newLocaleCode) {
                    final newLocale =
                        newLocaleCode != null ? Locale(newLocaleCode) : null;
                    settingsService.setLocale(newLocale);
                  },
                ),
              );
            },
          ),
          Divider(),
          _buildSectionHeader(l10n.settingIcons),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  spacing: 16.0, // Горизонтальный отступ между иконками
                  runSpacing: 16.0, // Вертикальный отступ между рядами
                  alignment: WrapAlignment.start,
                  children: [
                    _buildIconOption(
                      context: context,
                      iconAsset: 'assets/icons/default.png',
                      label: l10n.iconDefault,
                      iconName: null,
                    ),
                    _buildIconOption(
                      context: context,
                      iconAsset: 'assets/icons/flow.png',
                      label: l10n.iconFlow,
                      iconName: 'flow',
                    ),
                    _buildIconOption(
                      context: context,
                      iconAsset: 'assets/icons/purple.png',
                      label: l10n.iconPurple,
                      iconName: 'purple',
                    ),
                    _buildIconOption(
                      context: context,
                      iconAsset: 'assets/icons/legacy.png',
                      label: l10n.iconLegacy,
                      iconName: 'legacy',
                    ),
                    _buildIconOption(
                      context: context,
                      iconAsset: 'assets/icons/legacy_alt.png',
                      label: l10n.iconLegacyAlt,
                      iconName: 'legacy_alt',
                    ),
                    if (DateTime.now().month == 10)
                      _buildIconOption(
                        context: context,
                        iconAsset: 'assets/icons/barracuda.png',
                        label: l10n.iconBarracuda,
                        iconName: 'barracuda',
                      ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconOption({
    required BuildContext context,
    required String iconAsset,
    required String label,
    required String? iconName,
  }) {
    final bool isSelected = _currentIconName == iconName;
    final Color borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;

    return GestureDetector(
      onTap: () async {
        try {
          await DynamicAppIconFlutterPlus.setAlternateIconName(iconName);
          setState(() => _currentIconName = iconName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.appIconChangedSuccessfully)),
          );
        } catch (e) {
          print("Ошибка смены иконки: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.appIconChangeFailed)),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(iconAsset, width: 48, height: 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // Хелпер для заголовков секций
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color:
              Theme.of(
                context,
              ).colorScheme.primary, // Используем основной цвет темы
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
