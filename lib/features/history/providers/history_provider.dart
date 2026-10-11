import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/history_store.dart';
import '../models/measurement_group.dart';
import '../../../core/geometry/measurement.dart';

final historyStoreProvider = Provider<HistoryStore>(
  (ref) => LocalHistoryStore(),
);
final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<MeasurementGroup>>(
      HistoryNotifier.new,
    );

class HistoryNotifier extends AsyncNotifier<List<MeasurementGroup>> {
  Future<void> _queue = Future.value();
  @override
  Future<List<MeasurementGroup>> build() =>
      ref.read(historyStoreProvider).load();

  Future<void> _update(
    List<MeasurementGroup> Function(List<MeasurementGroup>) change,
  ) {
    final operation = _queue.then((_) async {
      final groups = await future;
      final next = change(groups);
      await ref.read(historyStoreProvider).save(next);
      state = AsyncData(List.unmodifiable(next));
    });
    _queue = operation.then((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<String> beginGroup({DateTime? at}) async {
    final time = at ?? DateTime.now();
    final id = time.microsecondsSinceEpoch.toString();
    await _update((groups) {
      final sameDay = groups.where(
        (g) =>
            g.startedAt.year == time.year &&
            g.startedAt.month == time.month &&
            g.startedAt.day == time.day,
      );
      final number =
          sameDay.fold(
            0,
            (max, g) => g.dailyNumber > max ? g.dailyNumber : max,
          ) +
          1;
      return [
        ...groups,
        MeasurementGroup(id: id, startedAt: time, dailyNumber: number),
      ];
    });
    return id;
  }

  Future<void> append(String groupId, MeasurementResult result) => _update((
    groups,
  ) {
    if (!groups.any((g) => g.id == groupId)) {
      throw StateError('Measurement group not found');
    }
    return groups
        .map(
          (g) =>
              g.id == groupId ? g.append(HistoryCapture.fromResult(result)) : g,
        )
        .toList();
  });

  Future<void> deleteEmptyGroup(String groupId) => _update((groups) {
    final matches = groups.where((group) => group.id == groupId);
    if (matches.any((group) => group.captures.isNotEmpty)) {
      throw StateError('Only groups without measurements can be deleted.');
    }
    return groups.where((group) => group.id != groupId).toList();
  });
}
