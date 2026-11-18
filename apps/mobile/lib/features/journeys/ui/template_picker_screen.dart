import 'package:flutter/widgets.dart';

import 'create/create_flow_screen.dart';

/// `/journeys/new`: step 1 (type picker) of the V2 five-step create flow.
///
/// The picker is no longer a separate grid screen: the whole flow lives in
/// [CreateFlowScreen] so every step keeps its state. The quick setup
/// (`CreateJourneyScreen`, `/journeys/new/:template`) stays as the fallback
/// for "Do this journey" frames and `?more=1`.
class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({this.resume = false, super.key});

  /// `?resume=1`: the Hub's "Continue creating" card reopens the saved draft.
  final bool resume;

  @override
  Widget build(BuildContext context) => CreateFlowScreen(resume: resume);
}
