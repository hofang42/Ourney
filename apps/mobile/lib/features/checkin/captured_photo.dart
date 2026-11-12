/// A photo handed from the capture screen to `/checkin` via `state.extra`
/// (`context.push(AppRoutes.checkin, extra: photo)`).
class CapturedPhoto {
  const CapturedPhoto({
    required this.journeyId,
    required this.path,
    required this.capturedAt,
    this.fromLibrary = false,
    this.initialMetricValue,
  });

  /// Journey selected in the capture screen's chip row.
  final String journeyId;

  /// Original (uncompressed) image file on local disk.
  final String path;

  /// When the shutter was pressed (or the library photo was picked), UTC.
  final DateTime capturedAt;

  /// Picked from the photo library (FR-C3): labelled "from library" and
  /// stored as `CheckInDraft.fromLibrary`.
  final bool fromLibrary;

  /// Optional metric value pre-selected on the camera HUD (e.g. Q2 slider).
  final double? initialMetricValue;
}
