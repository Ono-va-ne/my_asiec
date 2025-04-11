// Файл: lib/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ключи для хранения в SharedPreferences
const String _themeModeKey = 'app_theme_mode';
const String _themeAccentColorKey = 'app_theme_accent_color';
const String _themeMaterialYouKey = 'app_theme_material_you';
const String _defaultGroupIdKey = 'app_default_group_id';
const String _defaultTeacherIdKey = 'default_teacher_id';
const String _defaultRoomIdKey = 'default_room_id';

class SettingsService {
  // --- Notifiers для оповещения об изменениях ---
  // Используем ValueNotifier, чтобы MyApp мог слушать изменения темы
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Color?> accentColorNotifier = ValueNotifier(null); // null означает цвет по умолчанию
  final ValueNotifier<bool> materialYouNotifier = ValueNotifier(false);

  SharedPreferences? _prefs; // Экземпляр SharedPreferences

  // --- Инициализация ---
  // Загружает настройки при старте
  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Загрузка темы
    final themeModeIndex = _prefs?.getInt(_themeModeKey) ?? ThemeMode.system.index;
    themeModeNotifier.value = ThemeMode.values[themeModeIndex];

    // Загрузка акцентного цвета (храним как int)
    final colorValue = _prefs?.getInt(_themeAccentColorKey);
    accentColorNotifier.value = colorValue != null ? Color(colorValue) : null;

    // Загрузка Material You
    materialYouNotifier.value = _prefs?.getBool(_themeMaterialYouKey) ?? false;

    // Загрузка группы по умолчанию (просто загружаем, слушатель не нужен напрямую)
    // String? defaultGroupId = _prefs?.getString(_defaultGroupIdKey);
    // Можно добавить notifier и для группы, если нужно реагировать где-то еще
  }

  // --- Сохранение настроек ---

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_prefs == null) await loadSettings(); // Убедимся, что prefs загружены
    await _prefs?.setInt(_themeModeKey, mode.index);
    themeModeNotifier.value = mode; // Уведомляем слушателей
  }

  Future<void> setAccentColor(Color? color) async {
     if (_prefs == null) await loadSettings();
     if (color != null) {
        await _prefs?.setInt(_themeAccentColorKey, color.value);
     } else {
        await _prefs?.remove(_themeAccentColorKey); // Удаляем ключ, если цвет сброшен
     }
    accentColorNotifier.value = color; // Уведомляем
  }

   Future<void> setMaterialYou(bool enabled) async {
     if (_prefs == null) await loadSettings();
     await _prefs?.setBool(_themeMaterialYouKey, enabled);
     materialYouNotifier.value = enabled; // Уведомляем
   }
  

  Future<void> setDefaultRoomId(String? roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultRoomIdKey, roomId ?? ''); // Сохраняем ID или пустую строку, если null
  }

  String? getDefaultRoomId() {
    return _prefs?.getString(_defaultRoomIdKey);
  }

  Future<void> setDefaultTeacherId(String? teacherId) async {
    if (_prefs == null) await loadSettings();
    if (teacherId != null) {
      await _prefs?.setString(_defaultTeacherIdKey, teacherId);
    } else {
       await _prefs?.remove(_defaultTeacherIdKey);
    }
    print('setDefaultTeacherId: $teacherId'); // Для отладки
    // Тут можно добавить notifier, если нужно
  }

  String? getDefaultTeacherId() {
    return _prefs?.getString(_defaultTeacherIdKey);
  }


  Future<void> setDefaultGroupId(String? groupId) async {
    if (_prefs == null) await loadSettings();
    if (groupId != null) {
      await _prefs?.setString(_defaultGroupIdKey, groupId);
    } else {
       await _prefs?.remove(_defaultGroupIdKey);
    }
    // Тут можно добавить notifier, если нужно
  }

  String? getDefaultGroupId() {
     // Возвращаем сразу из SharedPreferences (можно кэшировать, если надо)
     return _prefs?.getString(_defaultGroupIdKey);
  }

}

// --- Глобальный экземпляр сервиса (Singleton Pattern) ---
// Чтобы иметь доступ к одному и тому же сервису из разных частей приложения
final SettingsService settingsService = SettingsService();