import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../data/group_daily_checkins_provider.dart';
import 'journey_progress.dart';
import 'run_stats.dart';
import 'timeline_window.dart' show downsample;

typedef WrappedCaption = ({String value, LocalDate date, CheckIn checkIn});
typedef WrappedCookSplit = ({
  String selfName,
  String partnerName,
  int self,
  int partner,
});

/// The caller's Wrapped stats, with a separate pair-only view of couple data.
class WrappedStats {
  const WrappedStats({
    required this.days,
    required this.moments,
    required this.total,
    required this.streak,
    required this.totalKm,
    required this.photos,
    required this.lastCaption,
    required this.lastPlace,
    required this.pace,
    this.weights = const [],
    this.coupleSlots = const [],
    this.memberStart,
    this.lastDay,
    this.firstCaption,
    this.longestCaption,
    this.noteCaption,
    this.busiestDay,
    this.moodLightDays = 0,
    this.minutesTotal = 0,
    this.minutesSessions = 0,
    this.minutesLongest,
    this.minutesPerDay = const {},
    this.kmPerDay = const {},
    this.runSessions = 0,
    this.fastestPace,
    this.placesInOrder = const [],
    this.couplePairedDays = const [],
    this.coupleSelfDays = const [],
    this.couplePartnerDays = const [],
    this.coupleCookSplit,
    this.coupleFiveHeartDishes = 0,
    this.chainDays = const [],
  });

  factory WrappedStats.from(JourneyProgress progress) {
    final start = progress.memberStart;
    final end = progress.lastDay;
    final total = math.max(1, start.daysUntil(end) + 1);
    bool inWindow(LocalDate date) =>
        !date.isBefore(start) && !date.isAfter(end);
    final dates = progress.checkInsByDate.keys.where(inWindow).toList()..sort();
    final photos = <CheckIn>[];
    final weights = <double>[];
    final captions = <WrappedCaption>[];
    final places = <String>{};
    final minutesPerDay = <LocalDate, int>{};
    var moments = 0;
    var lightDays = 0;
    var minutesTotal = 0;
    var minutesSessions = 0;
    var runSessions = 0;
    ({LocalDate date, int photoCount})? busiest;
    ({int value, LocalDate date})? longestSession;
    ({String value, LocalDate date})? fastestPace;
    var fastestSeconds = 0;
    var pacedKm = 0.0;
    var paceWeightedSeconds = 0.0;
    String? lastPlace;

    for (final date in dates) {
      final checkIns = progress.checkInsOn(date);
      final photoCount = checkIns.length;
      photos.add(checkIns.last);
      moments += photoCount;
      if (photoCount >= 3 && photoCount > (busiest?.photoCount ?? 0)) {
        busiest = (date: date, photoCount: photoCount);
      }
      if (latestMetric(checkIns) case final value? when value.isFinite) {
        weights.add(value);
      }
      if (checkIns.any((photo) => photo.extras.mood == 'light')) lightDays++;

      var dailyMinutes = 0;
      for (final photo in checkIns) {
        final extras = photo.extras;
        if (photo.caption?.trim() case final value? when value.isNotEmpty) {
          captions.add((value: value, date: date, checkIn: photo));
        }
        if (extras.place?.trim() case final place? when place.isNotEmpty) {
          places.add(place);
          lastPlace = place;
        }
        if (extras.minutes case final minutes? when minutes > 0) {
          dailyMinutes += minutes;
          minutesSessions++;
          if (minutes > (longestSession?.value ?? 0)) {
            longestSession = (value: minutes, date: date);
          }
        }
        if (extras.km case final km? when km.isFinite && km > 0) runSessions++;
        final pace = extras.pace;
        final secondsForAverage = paceSeconds(pace);
        final km = extras.km;
        if (secondsForAverage != null && km != null && km.isFinite && km > 0) {
          pacedKm += km;
          paceWeightedSeconds += km * secondsForAverage;
        }
        if (pace != null && _paceFormat.hasMatch(pace)) {
          final parts = pace.split(':');
          final seconds = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          if (fastestPace == null || seconds < fastestSeconds) {
            fastestSeconds = seconds;
            fastestPace = (value: pace, date: date);
          }
        }
      }
      minutesPerDay[date] = dailyMinutes;
      minutesTotal += dailyMinutes;
    }

    final runStats = RunStats.from(dates.map(progress.dayAt).toList());
    final avgPace = pacedKm > 0
        ? (paceWeightedSeconds / pacedKm).round()
        : null;
    final firstCaption = captions.firstOrNull?.date == dates.firstOrNull
        ? captions.firstOrNull
        : null;
    final stablyRankedCaptions = captions.reversed.toList();
    WrappedCaption? longestCaption;
    WrappedCaption? noteCaption;
    for (final caption in stablyRankedCaptions) {
      if (caption.value.runes.length >
          (longestCaption?.value.runes.length ?? 0)) {
        longestCaption = caption;
      }
      if (caption.value != firstCaption?.value &&
          caption.value.runes.length > (noteCaption?.value.runes.length ?? 0)) {
        noteCaption = caption;
      }
    }

    final couple = progress.couple;
    final coupleDates = couple.byDate.keys.where(inWindow).toList()..sort();
    final selfDays = <LocalDate>[];
    final partnerDays = <LocalDate>[];
    final pairedDays = <LocalDate>[];
    final cooks = <String, int>{};
    var fiveHeartDishes = 0;
    for (final date in coupleDates) {
      final pair = couple.byDate[date]!;
      final selfPhoto = progress.checkInsByDate[date] ?? pair[couple.myUserId];
      final partnerPhoto = pair[couple.partnerId];
      if (selfPhoto != null) selfDays.add(date);
      if (partnerPhoto != null) partnerDays.add(date);
      if (selfPhoto != null && partnerPhoto != null) pairedDays.add(date);
      final ownPhotos = progress.checkInsOn(date);
      final datePhotos = {
        for (final photo in [...couple.photosOn(date), ...ownPhotos])
          photo.id: photo,
      };
      for (final photo in datePhotos.values) {
        if (photo.extras.cook?.trim() case final name? when name.isNotEmpty) {
          cooks.update(name, (count) => count + 1, ifAbsent: () => 1);
        }
        if (photo.extras.hearts == 5 &&
            (photo.extras.dish?.trim().isNotEmpty ?? false)) {
          fiveHeartDishes++;
        }
      }
    }
    final selfName = couple.memberNames[couple.myUserId];
    final partnerName = couple.memberNames[couple.partnerId];
    final selfCount = cooks[selfName];
    final partnerCount = cooks[partnerName];
    final cookSplit =
        selfName != null &&
            partnerName != null &&
            selfName != partnerName &&
            selfCount != null &&
            partnerCount != null
        ? (
            selfName: selfName,
            partnerName: partnerName,
            self: selfCount,
            partner: partnerCount,
          )
        : null;
    final coupleDate = coupleDates.lastOrNull ?? dates.lastOrNull ?? progress.today;
    return WrappedStats(
      days: dates.length,
      moments: moments,
      total: total,
      streak: progress.journey.origin == JourneyOrigin.imported
          ? null
          : progress.summary.best,
      totalKm: runStats.totalKm,
      photos: List.unmodifiable(photos),
      lastCaption: captions.lastOrNull?.value,
      lastPlace: lastPlace,
      pace: avgPace == null ? null : formatPace(avgPace),
      weights: List.unmodifiable(weights),
      coupleSlots: couple.slotsOn(
        coupleDate,
        ownPhoto: progress.checkInsByDate[coupleDate],
      ),
      memberStart: start,
      lastDay: end,
      firstCaption: firstCaption,
      longestCaption: longestCaption,
      noteCaption: noteCaption,
      busiestDay: busiest,
      moodLightDays: lightDays,
      minutesTotal: minutesTotal,
      minutesSessions: minutesSessions,
      minutesLongest: longestSession,
      minutesPerDay: Map.unmodifiable(minutesPerDay),
      kmPerDay: Map.unmodifiable({
        for (final run in runStats.days) run.day.date: run.km,
      }),
      runSessions: runSessions,
      fastestPace: fastestPace,
      placesInOrder: List.unmodifiable(places),
      couplePairedDays: List.unmodifiable(pairedDays),
      coupleSelfDays: List.unmodifiable(selfDays),
      couplePartnerDays: List.unmodifiable(partnerDays),
      coupleCookSplit: cookSplit,
      coupleFiveHeartDishes: fiveHeartDishes,
      chainDays: List.unmodifiable([
        for (var i = 0; i < total; i++)
          progress.checkInsByDate.containsKey(start.addDays(i)),
      ]),
    );
  }

  /// Distinct check-in days (and every photo from those days).
  final int days;
  final int moments;
  final int total;
  int get memberTotal => total;
  final LocalDate? memberStart;
  final LocalDate? lastDay;

  final int? streak;
  final double totalKm;

  /// Latest photo per day and latest logged metric per day, oldest first.
  final List<CheckIn> photos;
  final List<double> weights;
  List<double> get weightsDownsampled => downsample(weights);
  final List<CouplePhotoSlot> coupleSlots;
  final String? lastCaption;
  final String? lastPlace;
  final String? pace;
  final WrappedCaption? firstCaption;
  final WrappedCaption? longestCaption;
  final WrappedCaption? noteCaption;
  final ({LocalDate date, int photoCount})? busiestDay;
  final int moodLightDays;
  final int minutesTotal;
  final int minutesSessions;
  final ({int value, LocalDate date})? minutesLongest;
  final Map<LocalDate, int> minutesPerDay;
  final Map<LocalDate, double> kmPerDay;
  final int runSessions;
  final ({String value, LocalDate date})? fastestPace;
  final List<String> placesInOrder;
  final List<LocalDate> couplePairedDays;
  final List<LocalDate> coupleSelfDays;
  final List<LocalDate> couplePartnerDays;
  final WrappedCookSplit? coupleCookSplit;
  final int coupleFiveHeartDishes;
  final List<bool> chainDays;

  int get percent => total == 0 ? 0 : (days * 100 / total).round();
  bool get showRatio => total > 0 && days * 10 >= total * 7;

  String kmTextFor(String locale) =>
      NumberFormat('0.#', locale).format(totalKm);

  List<CheckIn> sampleWall({int max = 30}) => _samplePhotos(photos, max);

  List<CheckIn> sampleRiffle({int max = 12}) =>
      _samplePhotos(sampleWall(), max);
}

final _paceFormat = RegExp(r'^[0-9]{1,2}:[0-5][0-9]$');

List<CheckIn> _samplePhotos(List<CheckIn> photos, int max) {
  if (max <= 0) return const [];
  if (photos.length <= max) return photos;
  if (max == 1) return [photos.first];
  return [
    for (var i = 0; i < max; i++)
      photos[(i * (photos.length - 1) / (max - 1)).round()],
  ];
}
