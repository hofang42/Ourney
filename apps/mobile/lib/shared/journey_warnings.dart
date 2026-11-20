import 'package:flutter/foundation.dart';

/// Counts create-flow settings (cover, colour, reminder, layout...) that the
/// server permanently rejected after the journey itself was created. The
/// journey is kept (rolling the user back would leave a journey that exists
/// but can never be created again); the create flow compares the value before
/// and after `create` and shows a non-fatal "some settings were not saved"
/// message when it grew.
final ValueNotifier<int> journeyExtrasRejected = ValueNotifier<int>(0);
