import 'dart:convert';

import 'package:simple_calibrator_poc/features/history/data/history_store.dart';
import 'package:simple_calibrator_poc/features/history/models/measurement_group.dart';

class MemoryHistoryStore implements HistoryStore {
  String raw = '[]';
  bool failWrites = false;
  @override
  Future<List<MeasurementGroup>> load() async => (jsonDecode(raw) as List)
      .map((g) => MeasurementGroup.fromJson(g as Map<String, dynamic>))
      .toList();
  @override
  Future<void> save(List<MeasurementGroup> groups) async {
    if (failWrites) throw StateError('Storage unavailable');
    raw = jsonEncode(groups.map((g) => g.toJson()).toList());
  }
}
