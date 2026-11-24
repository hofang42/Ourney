import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Shared ActivityKit attributes for Ourney's evening Check-In Window Live Activity.
/// Compiled into both `Runner` and `OurneyWidgetsExtension`.
/// Payload is strictly bounded (< 1 KB, well under ActivityKit's 4 KB limit) and
/// omits all health/weight metrics and photo bytes by design.
@available(iOS 16.2, *)
public struct OurneyCheckInAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    public var journeyId: String
    public var journeyTitle: String
    public var skinId: String
    public var colorVariant: Int
    public var typeIcon: String
    public var currentStreak: Int
    public var atRisk: Bool
    public var pendingCount: Int
    public var completedCount: Int
    public var totalActiveCount: Int
    public var deadlineUtc: Date
    public var windowStartUtc: Date
    public var locale: String
    public var redactTitleOnLockScreen: Bool
    public var isCompletedCelebration: Bool

    public init(
      journeyId: String,
      journeyTitle: String,
      skinId: String,
      colorVariant: Int,
      typeIcon: String,
      currentStreak: Int,
      atRisk: Bool,
      pendingCount: Int,
      completedCount: Int,
      totalActiveCount: Int,
      deadlineUtc: Date,
      windowStartUtc: Date,
      locale: String,
      redactTitleOnLockScreen: Bool,
      isCompletedCelebration: Bool
    ) {
      self.journeyId = journeyId
      self.journeyTitle = journeyTitle
      self.skinId = skinId
      self.colorVariant = colorVariant
      self.typeIcon = typeIcon
      self.currentStreak = currentStreak
      self.atRisk = atRisk
      self.pendingCount = pendingCount
      self.completedCount = completedCount
      self.totalActiveCount = totalActiveCount
      self.deadlineUtc = deadlineUtc
      self.windowStartUtc = windowStartUtc
      self.locale = locale
      self.redactTitleOnLockScreen = redactTitleOnLockScreen
      self.isCompletedCelebration = isCompletedCelebration
    }
  }

  public var windowKey: String

  public init(windowKey: String) {
    self.windowKey = windowKey
  }
}
#endif
