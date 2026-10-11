import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_group.dart';

abstract class HistoryStore {
  Future<List<MeasurementGroup>> load();
  Future<void> save(List<MeasurementGroup> groups);
}

class LocalHistoryStore implements HistoryStore {
  static const key = 'measurement_groups_v1';
  final _preferences = SharedPreferencesAsync();
  @override
  Future<List<MeasurementGroup>> load() async {
    final raw = await _preferences.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((g) => MeasurementGroup.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<MeasurementGroup> groups) => _preferences.setString(
    key,
    jsonEncode(groups.map((g) => g.toJson()).toList()),
  );
}
