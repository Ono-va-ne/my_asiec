import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Импортируем пакет для получения информации о приложении
import '../services/settings_service.dart'; // Импортируем сервис
import '../data/groups.dart'; // Импортируем список групп (fallback)
import '../services/groups_service.dart';
import '../models/group_info.dart';
import '../data/teachers.dart';
import '../data/rooms.dart'; // Импортируем список аудиторий
// import '../models/group_info.dart'; // Импортируем модель группы

Future<void> _launchTG(BuildContext context) async {
  // Формируем стандартную ссылку на пост VK

  final url = 'https://t.me/MyASIEC';
  final uri = Uri.parse(url);

  // Пытаемся открыть ссылку. LaunchMode.externalApplication
  // попытается открыть приложение TG, если оно установлено,
  // иначе откроет браузер.
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedGroupId; // Храним ID выбранной группы по умолчанию
  String? _selectedTeacherId;
  String? _selectedRoomId;
  String _appVersion = 'Загрузка...';
  final _groupsService = GroupsService();
  List<GroupInfo> _supabaseGroups = [];

  // Инициализируем с пустыми значениями
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadGroups();
    // Загружаем текущую выбранную группу при инициализации
    _selectedGroupId = settingsService.getDefaultGroupId();
    _selectedTeacherId = settingsService.getDefaultTeacherId();
    _selectedRoomId = settingsService.getDefaultRoomId();
    // Мы не используем ValueListenableBuilder здесь, т.к. нам не нужно
    // динамически перестраивать весь экран при смене группы,
    // достаточно обновить Dropdown при выборе.
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupsService.getGroups();
      if (mounted) setState(() => _supabaseGroups = groups);
    } catch (e) {
      print('Ошибка загрузки групп из Supabase: $e');
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // Получили информацию о пакете
      if (mounted) {
        // Проверяем, что виджет все еще "жив" перед обновлением состояния
        setState(() {
          _appVersion =
              packageInfo.version; // Обновляем переменную состояния с версией
        });
      }
    } catch (e) {
      print("Ошибка при загрузке информации о пакете: $e");
      if (mounted) {
        setState(() {
          _appVersion =
              'Ошибка загрузки версии'; // Показываем сообщение об ошибке, если что-то пошло не так
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String logo = 'assets/logo.svg';
    final Widget svg = SvgPicture.asset(
      logo,
      semanticsLabel: 'myASIEC Logo',
      height: 50,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );

    const String tg = 'assets/tg.svg';
    final Widget svgTg = SvgPicture.asset(
      tg,
      semanticsLabel: 'tg',
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // --- Секция: Группа по умолчанию ---
          _buildSectionHeader('Расписание'),
          ListTile(
            leading: Icon(Icons.group_outlined),
            title: Text('Группа'),
            // subtitle: Text('Будет выбрана при запуске приложения'),
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  // Используем ID группы как значение
                  value: _selectedGroupId,
                  hint: Text('Не выбрана'),
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
            title: Text('Препод.'),
            // subtitle: Text('Будет выбран при запуске приложения'),
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  // Используем ID группы как значение
                  value: _selectedTeacherId,
                  hint: Text('Не выбран(а)'),
                  // Фильтруем список, чтобы не было ошибки, если сохраненный ID невалиден
                  items:
                      availableTeachersData
                          .map(
                            (teacher) => DropdownMenuItem<String>(
                              value: teacher.id,
                              child: Text(
                                teacher.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
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
            title: Text('Ауд.'),
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  // Используем ID группы как значение
                  value: _selectedRoomId,
                  hint: Text('Не выбрана'),
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
                title: Text('Отображать перемены'),
                value: isBreaksEnabled,
                onChanged: (bool enabled) {
                  settingsService.setShowBreaksInSchedule(enabled);
                },
              );
            },
          ),

          Divider(),

          // --- Секция: Тема ---
          _buildSectionHeader('Оформление'),
          // Выбор режима темы
          ValueListenableBuilder<ThemeMode>(
            valueListenable: settingsService.themeModeNotifier,
            builder: (context, currentMode, _) {
              return ListTile(
                leading: Icon(Icons.brightness_6_outlined),
                title: Text('Режим темы'),
                trailing: DropdownButton<ThemeMode>(
                  value: currentMode,
                  underline: SizedBox.shrink(), // Убираем подчеркивание
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Системная'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Светлая'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Тёмная'),
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
                title: Text('Динамические оформление'),
                subtitle: Text('Использовать цвета обоев (Android 12+)'),
                value: isMaterialYouEnabled,
                onChanged: (bool enabled) {
                  settingsService.setMaterialYou(enabled);
                },
              );
            },
          ),
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
