import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group_info.dart';

class GroupsService {
  static const String _boxName = 'cachedGroupsBox';
  static const String _cacheKey = 'groups';

  final _client = Supabase.instance.client;

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<GroupInfo>> getGroups({bool forceRefresh = false}) async {
    final box = await _openBox();

    if (!forceRefresh) {
      final cached = box.get(_cacheKey);
      if (cached != null && cached is List) {
        try {
          return (cached as List)
              .map((e) => GroupInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } catch (_) {
          // игнорируем некорректный кэш и продолжим запрос к сети
        }
      }
    }

    // Попробуем выполнить запрос разными способами (для совместимости с разными версиями SDK)
    dynamic query = (_client.from('groups').select('*') as dynamic);
    dynamic response;

    // Попытка 1: .execute()
    try {
      response = await query.execute();
    } catch (_) {
      // Попытка 2: .get()
      try {
        response = await query.get();
      } catch (_) {
        // Попытка 3: возможно query сам по себе Future/Stream
        try {
          response = await query;
        } catch (e) {
          // Все попытки упали — вернём кэш, если есть, иначе бросим
          final cached = box.get(_cacheKey);
          if (cached != null && cached is List) {
            return (cached as List)
                .map((e) => GroupInfo.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
          rethrow;
        }
      }
    }

    // Нормализуем ответ в List<Map<String, dynamic>>
    List<Map<String, dynamic>> rows = [];

    try {
      if (response == null) throw Exception('Empty response from Supabase');

      // Если вернулся уже список
      if (response is List) {
        rows = (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        // Попробуем получить поле data (PostgrestResponse / PostgrestList и т.д.)
        dynamic dataField;
        try {
          dataField = (response as dynamic).data;
        } catch (_) {
          dataField = null;
        }

        // Если в объекте есть поле error — проверим его
        try {
          final err = (response as dynamic).error;
          if (err != null) {
            // при ошибке вернём кэш, если есть
            final cached = box.get(_cacheKey);
            if (cached != null && cached is List) {
              return (cached as List)
                  .map((e) => GroupInfo.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
            }
            throw Exception(err.toString());
          }
        } catch (_) {
          // игнорируем отсутствие поля error
        }

        if (dataField is List) {
          rows = (dataField as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (response is Map && response.containsKey('data') && response['data'] is List) {
          rows = (response['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          throw Exception('Unexpected response shape from Supabase: ${response.runtimeType}');
        }
      }
    } catch (e) {
      // при ошибке парсинга вернём кэш если есть, иначе пробросим
      final cached = box.get(_cacheKey);
      if (cached != null && cached is List) {
        return (cached as List)
            .map((e) => GroupInfo.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      rethrow;
    }

    // Сохраняем "сырые" map'ы в кэш и возвращаем модели
    await box.put(_cacheKey, rows);
    return rows.map((e) => GroupInfo.fromJson(e)).toList();
  }
}