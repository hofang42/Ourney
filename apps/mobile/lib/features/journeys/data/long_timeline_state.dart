import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// The two views of a long journey's timeline.
enum LongTimelineMode { recent, month }

/// What the user chose on the long-journey timeline of one journey. Lives in
/// memory for the session (not persisted): leaving the screen and coming
/// back keeps it.
class LongTimelineState {
  const LongTimelineState({
    this.mode = LongTimelineMode.recent,
    this.open,
    this.chipYear,
    this.range30 = false,
  });

  final LongTimelineMode mode;

  /// Month ids the user has opened. Null until the user toggles one: the
  /// month of today is then the one open month and follows the calendar.
  final Set<int>? open;

  /// Year filter of the jump chips (journeys over 12 months).
  final int? chipYear;

  /// Quiet curve: last 30 days instead of the whole journey.
  final bool range30;

  LongTimelineState copyWith({
    LongTimelineMode? mode,
    Set<int>? open,
    int? Function()? chipYear,
    bool? range30,
  }) => LongTimelineState(
    mode: mode ?? this.mode,
    open: open ?? this.open,
    chipYear: chipYear == null ? this.chipYear : chipYear(),
    range30: range30 ?? this.range30,
  );
}

class LongTimelineNotifier extends Notifier<LongTimelineState> {
  LongTimelineNotifier(this.journeyId);

  final String journeyId;

  @override
  LongTimelineState build() {
    // A different account starts clean.
    ref.watch(currentUserIdProvider);
    return const LongTimelineState();
  }

  void setMode(LongTimelineMode mode) => state = state.copyWith(mode: mode);

  /// Opens or closes [id]; [current] is the default open month.
  void toggleMonth(int id, {required int? current}) {
    final open = {...(state.open ?? {?current})};
    if (!open.remove(id)) open.add(id);
    state = state.copyWith(open: open);
  }

  void setChipYear(int? year) => state = state.copyWith(chipYear: () => year);

  void setRange30({required bool value}) =>
      state = state.copyWith(range30: value);
}

/// Per-journey (by id) long-timeline choices, kept in memory.
final longTimelineProvider =
    NotifierProvider.family<
      LongTimelineNotifier,
      LongTimelineState,
      String
    >(LongTimelineNotifier.new);