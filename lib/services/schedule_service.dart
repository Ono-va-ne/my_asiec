import 'package:flutter/foundation.dart';

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

  /// Time-to-live for cached schedules. Adjust as needed.
  Duration ttl = const Duration(minutes: 30);

  String makeKey(String type, String objectId, String start, String end) {
    return '$type|$objectId|$start|$end';
  }

  List<DailySchedule>? getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > ttl) {
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
}
