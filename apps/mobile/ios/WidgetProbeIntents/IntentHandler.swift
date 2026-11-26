import Intents
import OSLog

final class IntentHandler: INExtension, OurneyProbeSelectionIntentHandling {
  private let logger = Logger(subsystem: "com.hofang42.ourney.widgets", category: "provider")

  override func handler(for intent: INIntent) -> Any {
    self
  }

  func provideOptionOptionsCollection(
    for intent: OurneyProbeSelectionIntent,
    with completion: @escaping (INObjectCollection<OurneyProbeOption>?, Error?) -> Void
  ) {
    logger.notice("probe sirikit query suggestions")
    let options = ["Amber", "Blue", "Coral"].map { OurneyProbeOption(identifier: $0, display: $0) }
    completion(INObjectCollection(items: options), nil)
  }

  func defaultOption(for intent: OurneyProbeSelectionIntent) -> OurneyProbeOption? {
    logger.notice("probe sirikit query default")
    return OurneyProbeOption(identifier: "Amber", display: "Amber")
  }
}
