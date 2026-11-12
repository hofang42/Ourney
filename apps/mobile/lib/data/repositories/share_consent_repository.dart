import 'package:ourney_core/ourney_core.dart';

import '../social_context.dart';
import '../social_mapping.dart';

/// [ShareConsentRepository] over the v1.3 RPCs (S29–S31).
class DataShareConsentRepository implements ShareConsentRepository {
  DataShareConsentRepository(this.social);

  final SocialContext social;

  void refresh() => social.changed();

  List<ShareConsent> _list(Object? json) => [
    for (final r in rowsOf(json)) consentFromJson(r),
  ];

  @override
  Stream<List<ShareConsent>> watchForJourney(String journeyId) => social.watch(
    () => social.call('share_consents', {'p_journey': journeyId}, _list),
  );

  @override
  Stream<List<ShareConsent>> watchMyPending() =>
      social.watch(() => social.call('my_pending_consents', const {}, _list));

  @override
  Future<void> request(String journeyId) =>
      social.mutate('request_share_consent', {'p_journey': journeyId});

  @override
  Future<void> respond(String journeyId, {required bool accept}) =>
      social.mutate('respond_share_consent', {
        'p_journey': journeyId,
        'p_accept': accept,
      });

  @override
  Future<void> withdraw(String journeyId) =>
      social.mutate('withdraw_share_consent', {'p_journey': journeyId});
}
