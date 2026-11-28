import 'package:ourney_core/ourney_core.dart';

/// Nearest openable dates on either side, independent of input order.
({LocalDate? prev, LocalDate? next}) dayNeighbors(
  Iterable<LocalDate> openable,
  LocalDate current,
) {
  LocalDate? prev;
  LocalDate? next;
  for (final date in openable.toSet()) {
    final delta = date.daysUntil(current);
    if (delta > 0 && (prev == null || prev.daysUntil(date) > 0)) prev = date;
    if (delta < 0 && (next == null || date.daysUntil(next) > 0)) next = date;
  }
  return (prev: prev, next: next);
}

/// The authored day number, including check-ins after a fixed term ends.
int? journeyDayOrdinal(Journey journey, LocalDate date) {
  final day = journey.startDate.daysUntil(date) + 1;
  return day < 1 ? null : day;
}
