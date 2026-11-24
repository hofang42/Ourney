import 'package:flutter/widgets.dart';

import 'create/create_flow_screen.dart';
import 'create/create_type_option.dart' show CreateWho;

/// `/journeys/new`: step 1 (type picker) of the V2 five-step create flow.
///
/// The picker is no longer a separate grid screen: the whole flow lives in
/// [CreateFlowScreen] so every step keeps its state. The quick setup
/// (`CreateJourneyScreen`, `/journeys/new/:template`) stays as the fallback
/// for "Do this journey" frames and `?more=1`.
class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({
    this.resume = false,
    this.initialWho,
    super.key,
  });

  /// `?resume=1`: the Hub's "Continue creating" card reopens the saved draft.
  final bool resume;

  /// `?who=group` (or `couple` / `solo`): preselects step 3 ("Who is coming
  /// along?"), e.g. when starting a journey together from a friend sheet.
  final CreateWho? initialWho;

  static CreateWho? parseWho(String? raw) => CreateFlowScreen.parseWho(raw);

  @override
  Widget build(BuildContext context) =>
      CreateFlowScreen(resume: resume, initialWho: initialWho);
}
