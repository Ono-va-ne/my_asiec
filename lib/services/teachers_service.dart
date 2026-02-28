import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/teacher_info.dart';

class TeachersService {
  static const String _boxName = 'cachedTeachersBox';
  static const String _cacheKey = 'teachers';

  final _client = Supabase.instance.client;

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<TeacherInfo>> getTeachers({bool forceRefresh = false}) async {
    final box = await _openBox();
    
    // Если не требуется принудительное обновление, сначала проверяем кэш.
    if (!forceRefresh) {
      final cached = box.get(_cacheKey);
      if (cached != null && cached is List) {
        try {
          print('TeachersService: Returning teachers from cache.');
          return (cached)
                .map((e) => TeacherInfo.fromJson(Map<String, dynamic>.from(e)))
                .toList();
        } catch (e) {
          print('TeachersService: Error parsing cached teachers: $e. Fetching from network.');
        }
      }
    }

    try {
      print('TeachersService: Fetching teachers from Supabase...');
      final List<Map<String, dynamic>> rows = await _client.from('teachers').select();
      print('TeachersService: Received ${rows.length} teachers from Supabase.');

      await box.put(_cacheKey, rows);
      return rows.map((e) => TeacherInfo.fromJson(e)).toList();
    } catch (e) {
      print('TeachersService: Error fetching teachers from Supabase: $e');
      final cached = box.get(_cacheKey);
      if (cached != null && cached is List) {
        try {
          print('TeachersService: Network request failed, returning teachers from fallback cache.');
          return (cached).map((e) => TeacherInfo.fromJson(Map<String, dynamic>.from(e))).toList();
        } catch (cacheError) {
          print('TeachersService: Error parsing fallback cache: $cacheError');
          rethrow;
        }
      }
      rethrow;
    }
  }
}
