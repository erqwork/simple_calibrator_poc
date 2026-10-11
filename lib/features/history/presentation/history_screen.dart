import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/history_provider.dart';
import '../../../shared/widgets/pair_result.dart';
import '../../scanner/presentation/scanner_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _pageSize = 14;
  int _visibleCount = _pageSize;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 160) _loadMore();
  }

  void _loadMore() {
    final total = ref.read(historyProvider).asData?.value.length ?? 0;
    if (_visibleCount < total) {
      setState(
        () => _visibleCount = (_visibleCount + _pageSize).clamp(0, total),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Measurement history'),
      actions: [
        IconButton(
          tooltip: 'New measurement group',
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
          ),
        ),
      ],
    ),
    body: ref
        .watch(historyProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('History could not be loaded.'),
                TextButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (groups) => groups.isEmpty
              ? const Center(child: Text('No scanner visits yet.'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: groups.length > _visibleCount
                      ? _visibleCount + 1
                      : groups.length,
                  itemBuilder: (context, index) {
                    if (index == _visibleCount) {
                      return TextButton(
                        onPressed: _loadMore,
                        child: const Text('Load 14 more'),
                      );
                    }
                    final group = groups[groups.length - 1 - index];
                    if (group.captures.isEmpty) {
                      return Dismissible(
                        key: ValueKey(group.id),
                        direction: DismissDirection.horizontal,
                        background: const _DeleteBackground(
                          alignment: Alignment.centerLeft,
                        ),
                        secondaryBackground: const _DeleteBackground(
                          alignment: Alignment.centerRight,
                        ),
                        confirmDismiss: (_) async {
                          try {
                            await ref
                                .read(historyProvider.notifier)
                                .deleteEmptyGroup(group.id);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not delete this entry. Please try again.',
                                  ),
                                ),
                              );
                            }
                          }
                          // The provider removes the row only after storage succeeds.
                          return false;
                        },
                        child: ListTile(
                          title: Text(
                            '${group.startedAt.month}/${group.startedAt.day}/${group.startedAt.year} '
                            'Group ${group.dailyNumber} ${TimeOfDay.fromDateTime(group.startedAt).format(context)}',
                          ),
                          subtitle: const Text('No successful measurements'),
                          tileColor: Theme.of(context).colorScheme.surface,
                        ),
                      );
                    }
                    return ExpansionTile(
                      key: PageStorageKey(group.id),
                      textColor: Colors.black87,
                      collapsedTextColor: Colors.black87,
                      collapsedBackgroundColor: group.adjustmentsToIdeal != null
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      backgroundColor: group.adjustmentsToIdeal != null
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      title: Text(
                        '${group.startedAt.month}/${group.startedAt.day}/${group.startedAt.year} '
                        'Group ${group.dailyNumber} ${TimeOfDay.fromDateTime(group.startedAt).format(context)}',
                      ),
                      subtitle: Text(
                        group.captures.isEmpty
                            ? 'No successful measurements'
                            : '${group.captures.length} captures · ${group.adjustmentsToIdeal == null ? 'Ideal distances not reached' : '${group.adjustmentsToIdeal} adjustments to first all-pass result'}',
                      ),
                      children: [
                        for (var i = 0; i < group.captures.length; i++)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i == 0 ? 'Initial measurement' : 'Adjustment $i'} · '
                                  '${TimeOfDay.fromDateTime(group.captures[i].timestamp).format(context)}',
                                ),
                                for (final distance
                                    in group.captures[i].distances)
                                  PairResult(distance, highContrast: true),
                                Text(
                                  'Tolerance ±${group.captures[i].config.allowedDeviationMm} mm · stable approximate measurement',
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
  );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.alignment});
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.errorContainer,
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Icon(
      Icons.delete_outline,
      color: Theme.of(context).colorScheme.onErrorContainer,
    ),
  );
}
