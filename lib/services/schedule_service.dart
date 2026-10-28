import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_schedule.dart';

class _CacheEntry {
  final DateTime fetchedAt;
  final List<DailySchedule> data;

  _CacheEntry(this.fetchedAt, this.data);
}

class ScheduleService {
  ScheduleService._privateConstructor();
  static final ScheduleService instance = ScheduleService._privateConstructor();

  final Map<String, _CacheEntry> _cache = {};
  static const _cachePrefix = 'schedule_cache_';

  /// Time-to-live for cached schedules. Adjust as needed.
  Duration ttl = const Duration(minutes: 30);

  String makeKey(String type, String objectId, String start, String end) {
    return '$type|$objectId|$start|$end';
  }

  Future<List<DailySchedule>?> getCached(String key) async {
    final entry = _cache[key];
    if (entry != null) {
      if (DateTime.now().difference(entry.fetchedAt) <= ttl) return entry.data;
      _cache.remove(key);
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(key));
    if (raw == null) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
      if (DateTime.now().difference(fetchedAt) > ttl) {
        await prefs.remove(_storageKey(key));
        return null;
      }
      final data = (json['data'] as List<dynamic>)
          .whereType<Map>()
          .map((item) => DailySchedule.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _cache[key] = _CacheEntry(fetchedAt, data);
      return data;
    } catch (_) {
      await prefs.remove(_storageKey(key));
      return null;
    }
  }

  Future<void> setCached(String key, List<DailySchedule> data) async {
    final fetchedAt = DateTime.now();
    _cache[key] = _CacheEntry(fetchedAt, data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(key),
      jsonEncode({
        'fetchedAt': fetchedAt.toIso8601String(),
        'data': data.map((item) => item.toJson()).toList(),
      }),
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('ScheduleService: cached key=$key');
    }
  }

  String _storageKey(String key) => '$_cachePrefix${base64Url.encode(utf8.encode(key))}';

  Future<void> clear() async {
    _cache.clear();
  }

  /// Remove a single cache entry by key. Returns true if an entry was removed.
  Future<bool> removeCached(String key) async {
    final wasInMemory = _cache.remove(key) != null;
    final prefs = await SharedPreferences.getInstance();
    final wasPersisted = await prefs.remove(_storageKey(key));
    return wasInMemory || wasPersisted;
  }

  /*
  List<DailySchedule>? getCached(String key) {
      // expired
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  void setCached(String key, List<DailySchedule> data) {
    _cache[key] = _CacheEntry(DateTime.now(), data);
    if (kDebugMode) {
      // ignore: avoid_print
      print('ScheduleService: cached key=$key');
    }
  }

  void clear() => _cache.clear();

  /// Remove a single cache entry by key. Returns true if an entry was removed.
  bool removeCached(String key) {
    return _cache.remove(key) != null;
  }
  */
}
