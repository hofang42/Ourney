import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart' show currentUserIdProvider;
import 'captured_photo.dart';
import 'photo_compressor.dart';
import 'post_extras.dart';

typedef CheckinDraft = ({
  CapturedPhoto photo,
  String caption,
  String metric,
  PostExtrasDraft extras,
});

/// Unposted check-ins for the current account and app session.
final checkinDraftsProvider = Provider<CheckinDrafts>((ref) {
  ref.watch(currentUserIdProvider);
  final drafts = CheckinDrafts(ref.watch(draftFilesProvider));
  ref.onDispose(drafts.dispose);
  return drafts;
});

class CheckinDrafts extends ChangeNotifier {
  CheckinDrafts(this._files);

  final DraftFiles _files;
  final _drafts = <String, CheckinDraft>{};
  bool _disposed = false;

  CapturedPhoto? photoFor(String journeyId) => _drafts[journeyId]?.photo;

  CheckinDraft? take(String journeyId) {
    final draft = _drafts.remove(journeyId);
    if (draft != null) _notifyAfterLifecycle();
    return draft;
  }

  void save(CheckinDraft draft) {
    final photo = draft.photo;
    if (_disposed) {
      unawaited(_files.discard([photo.path]));
      return;
    }
    final previous = _drafts[photo.journeyId]?.photo.path;
    _drafts[photo.journeyId] = draft;
    if (previous != null && previous != photo.path) {
      unawaited(_files.discard([previous]));
    }
    _notifyAfterLifecycle();
  }

  void _notifyAfterLifecycle() {
    // The editor transfers ownership during initState and dispose.
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    final paths = [for (final draft in _drafts.values) draft.photo.path];
    _drafts.clear();
    if (paths.isNotEmpty) unawaited(_files.discard(paths));
    super.dispose();
  }
}
