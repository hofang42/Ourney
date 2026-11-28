import 'package:ourney_core/ourney_core.dart';

/// Where a durable import job stands. A job only moves forward.
enum ImportPhase {
  /// Photos are being compressed and copied into app storage.
  preparing('preparing'),

  /// Every photo is prepared; the journey is created on the server.
  creating('creating'),

  /// The journey exists; each photo becomes one check-in.
  uploading('uploading'),

  /// Nothing left to do (photos that could not be saved stay marked).
  done('done');

  const ImportPhase(this.wire);
  final String wire;

  static ImportPhase fromWire(String wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => preparing);
}

enum ImportPhotoState {
  pending('pending'),
  saved('saved'),
  failed('failed');

  const ImportPhotoState(this.wire);
  final String wire;

  static ImportPhotoState fromWire(String wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => pending);
}

/// Why one photo could not be saved (shown as a reason, never raw text).
enum ImportFailure {
  /// The picked file is gone or cannot be decoded.
  unreadable('unreadable'),

  /// The device or the server was unreachable.
  offline('offline'),

  /// The server refused the photo's date.
  badDate('bad_date'),

  /// The server refused the journey itself (name, dates, skin).
  invalid('invalid'),

  /// Anything else.
  unknown('unknown');

  const ImportFailure(this.wire);
  final String wire;

  static ImportFailure? fromWire(String? wire) => wire == null
      ? null
      : values.firstWhere((v) => v.wire == wire, orElse: () => unknown);
}

/// One photo of an import job. Its [id] is also the id of the check-in it
/// becomes, so a retry can never add a second copy.
class ImportJobPhoto {
  const ImportJobPhoto({
    required this.id,
    required this.position,
    required this.date,
    required this.secondsOfDay,
    this.caption,
    this.sourcePath,
    this.photoFile,
    this.thumbFile,
    this.offsetMinutes,
    this.dedupeKey,
    this.state = ImportPhotoState.pending,
    this.failure,
  });

  final String id;
  final int position;

  /// The picked original; kept until the photo is saved (a resume re-reads it).
  final String? caption;
  final String? sourcePath;

  /// Compressed JPEG + thumbnail in app storage, once prepared.
  final String? photoFile;
  final String? thumbFile;
  final LocalDate date;
  final int secondsOfDay;
  final int? offsetMinutes;

  /// Content key of the picked photo, to spot a re-pick of the same one.
  final String? dedupeKey;
  final ImportPhotoState state;
  final ImportFailure? failure;

  bool get prepared => photoFile != null && thumbFile != null;
}

class ImportJob {
  const ImportJob({
    required this.id,
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.firstDate,
    required this.lastDate,
    required this.timezone,
    required this.createdAt,
    required this.photos,
    required this.ownerId,
    this.layout,
    this.continues = false,
    this.phase = ImportPhase.preparing,
    this.paused = false,
    this.createFailure,
  });

  /// The account that started the job: nobody else may run it.
  final String ownerId;

  /// The person paused saving; only they resume it.
  final bool paused;

  /// Why creating the journey failed last time (null: not failed).
  final ImportFailure? createFailure;

  /// The journey's client id: the server's create is idempotent on it.
  final String id;
  final String title;
  final String emoji;
  final TemplateId templateId;
  final LocalDate firstDate;
  final LocalDate lastDate;
  final String timezone;
  final PersonaSkinId? layout;
  final bool continues;
  final ImportPhase phase;
  final DateTime createdAt;
  final List<ImportJobPhoto> photos;

  int get saved =>
      photos.where((p) => p.state == ImportPhotoState.saved).length;
  int get failed =>
      photos.where((p) => p.state == ImportPhotoState.failed).length;
  int get pending =>
      photos.where((p) => p.state == ImportPhotoState.pending).length;

  /// Every photo is saved: nothing is kept for a later retry.
  bool get complete => photos.every((p) => p.state == ImportPhotoState.saved);

  /// The journey to create. Its dates span the photos that can still be
  /// saved (a photo that could not be read must not widen the range).
  ImportedJourneyDraft get draft {
    final usable = photos.where((p) => p.state != ImportPhotoState.failed);
    final source = usable.isEmpty ? photos : usable;
    var first = firstDate;
    var last = lastDate;
    if (source.isNotEmpty) {
      first = source.map((p) => p.date).reduce((a, b) => a.isBefore(b) ? a : b);
      last = source.map((p) => p.date).reduce((a, b) => a.isAfter(b) ? a : b);
    }
    return ImportedJourneyDraft(
      id: id,
      title: title,
      emoji: emoji,
      templateId: templateId,
      firstDate: first,
      lastDate: last,
      timezone: timezone,
      layout: layout,
      continues: continues,
    );
  }
}
