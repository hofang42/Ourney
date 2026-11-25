import Foundation
import SwiftUI

/// Explicit Vietnamese (`vi` default) and English (`en`) localization helper for Ourney widgets
/// and Live Activities (§5.2).
/// Resolves `snapshot.locale` first so toggling language inside Ourney Settings immediately
/// updates every widget and Live Activity without restarting iOS.
public enum WidgetL10n {
  public static func isEnglish(_ locale: String?) -> Bool {
    if let raw = locale?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
      return !raw.lowercased().hasPrefix("vi")
    }
    let preferred = Locale.preferredLanguages.first ?? "en"
    return !preferred.lowercased().hasPrefix("vi")
  }

  public static func tr(_ key: String) -> LocalizedStringKey {
    LocalizedStringKey(key)
  }

  // MARK: - Day & Progress Labels

  public static func dayLabel(dayNumber: Int, totalDays: Int?, locale: String) -> String {
    let en = isEnglish(locale)
    if let total = totalDays, total > 0 {
      return en ? "DAY \(dayNumber)/\(total)" : "NGÀY \(dayNumber)/\(total)"
    }
    return en ? "DAY \(dayNumber)" : "NGÀY \(dayNumber)"
  }

  public static func streakCountLabel(_ streak: Int, locale: String) -> String {
    let en = isEnglish(locale)
    if en {
      return streak == 1 ? "1 day" : "\(streak) days"
    }
    return "\(streak) ngày"
  }

  public static func todayHeaderProgress(completed: Int, total: Int, locale: String) -> String {
    let en = isEnglish(locale)
    return en ? "TODAY · \(completed)/\(total) DONE" : "HÔM NAY · \(completed)/\(total) ĐÃ CHỤP"
  }

  // MARK: - CTAs & Status Chips

  public static func snapShort(locale: String) -> String {
    isEnglish(locale) ? "Snap" : "Chụp"
  }

  public static func snapNow(locale: String) -> String {
    isEnglish(locale) ? "Snap now" : "Chụp ngay"
  }

  public static func snapYours(locale: String) -> String {
    isEnglish(locale) ? "Snap yours" : "Chụp phần bạn"
  }

  public static func doneShort(locale: String) -> String {
    isEnglish(locale) ? "Done" : "Xong"
  }

  public static func checkedInToday(locale: String) -> String {
    isEnglish(locale) ? "Checked in today" : "Đã chụp hôm nay"
  }

  public static func phaseBadgeText(
    phase: OurneyTimePhase,
    skinId: String,
    streak: Int,
    locale: String
  ) -> String {
    let en = isEnglish(locale)
    switch phase {
    case .completed:
      return en ? "Checked in" : "Đã hoàn thành"
    case .urgentAtRisk:
      // Gentler Streak lesson (§1.1): quietTransformer uses calm copy even near midnight.
      if skinId == "quiet" {
        return en ? "Still time for today" : "Vẫn kịp cho hôm nay"
      }
      return en ? "Keep your \(streak)d streak!" : "Giữ chuỗi \(streak) ngày!"
    case .eveningCue:
      return en ? "Evening window open" : "Đến giờ chụp tối nay"
    case .daytime:
      return en ? "Waiting for today's photo" : "Chờ ảnh hôm nay"
    }
  }

  // MARK: - Squad Copy

  public static func squadCheckedInBadge(done: Int, total: Int, locale: String) -> String {
    let en = isEnglish(locale)
    return en ? "\(done)/\(total) CHECKED IN" : "\(done)/\(total) ĐÃ CHỤP"
  }

  public static func coupleStatusText(doneCount: Int, locale: String) -> String {
    let en = isEnglish(locale)
    switch doneCount {
    case 2...:
      return en ? "Both checked in today" : "Cả hai đã chụp hôm nay"
    case 1:
      return en ? "1 of 2 moments captured" : "1/2 khoảnh khắc đã lưu"
    default:
      return en ? "Waiting for today's moments" : "Chờ khoảnh khắc hôm nay"
    }
  }

  public static func viewSquad(locale: String) -> String {
    isEnglish(locale) ? "View squad" : "Xem nhóm"
  }

  // MARK: - Empty States (Including Unsynced, SignedOut, NoJourneys, SoloOnly — §A.3 & Rank 5)

  public static func unsyncedTitle(locale: String) -> String {
    isEnglish(locale) ? "Tap to sync your journeys" : "Chạm để đồng bộ hành trình"
  }

  public static func unsyncedSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Open Ourney once to load your active journeys."
      : "Mở Ourney 1 lần để tải dữ liệu lên widget."
  }

  public static func unsyncedCta(locale: String) -> String {
    isEnglish(locale) ? "Sync now" : "Đồng bộ ngay"
  }

  public static func unsyncedLockScreenStatus(locale: String) -> String {
    isEnglish(locale) ? "Tap to sync" : "Chạm để đồng bộ"
  }

  public static func signedOutTitle(locale: String) -> String {
    isEnglish(locale) ? "Sign in to Ourney" : "Đăng nhập Ourney"
  }

  public static func signedOutSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Sign in to view your streaks & check-ins."
      : "Đăng nhập để xem chuỗi ngày & tiến độ."
  }

  public static func signedOutCta(locale: String) -> String {
    isEnglish(locale) ? "Sign in" : "Đăng nhập"
  }

  public static func noJourneysTitle(locale: String) -> String {
    isEnglish(locale) ? "Start your first journey" : "Bắt đầu hành trình đầu tiên"
  }

  public static func noJourneysSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "One photo a day to build your story."
      : "Mỗi ngày một tấm ảnh lưu giữ kỷ niệm."
  }

  public static func noJourneysCta(locale: String) -> String {
    isEnglish(locale) ? "Create journey" : "Tạo hành trình"
  }

  public static func soloOnlySquadSubtitle(soloCount: Int, locale: String) -> String {
    let safeCount = max(soloCount, 1)
    if isEnglish(locale) {
      let noun = safeCount == 1 ? "1 solo journey" : "\(safeCount) solo journeys"
      return "You have \(noun) — start or join a Squad, or use the Today widget."
    }
    return "Bạn có \(safeCount) hành trình cá nhân — tạo nhóm mới hoặc dùng widget Hôm nay."
  }

  public static func emptyTodayTitle(locale: String) -> String {
    isEnglish(locale) ? "Ready for Day 1?" : "Bắt đầu hành trình mới"
  }

  public static func emptyTodaySubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Open Ourney to create or sync your photo journey."
      : "Mở Ourney để tạo hoặc đồng bộ hành trình ảnh mỗi ngày."
  }

  public static func emptySquadTitle(locale: String) -> String {
    isEnglish(locale) ? "No Squad journey yet" : "Chưa có nhóm đồng hành"
  }

  public static func emptySquadSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Join a Squad or Couple journey to see everyone's daily check-in."
      : "Tham gia nhóm hoặc hành trình cặp đôi để cùng giữ chuỗi mỗi ngày."
  }

  public static func openOurney(locale: String) -> String {
    isEnglish(locale) ? "Open Ourney" : "Mở Ourney"
  }

  // MARK: - Configurable Widget Entity Picker Copy (§B.2, §B.4)

  public static func autoJourneyOptionTitle(locale: String) -> String {
    isEnglish(locale) ? "Automatic (Recommended)" : "Tự động (Đề xuất)"
  }

  public static func autoJourneyOptionSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Auto: Next pending today or featured streak"
      : "Tự động: hành trình cần chụp hôm nay"
  }

  public static func autoSquadOptionTitle(locale: String) -> String {
    isEnglish(locale) ? "Automatic (Recommended)" : "Tự động (Đề xuất)"
  }

  public static func autoSquadOptionSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Auto: Active squad or couple today"
      : "Tự động: nhóm cần chụp hôm nay"
  }

  public static func journeyEntitySubtitle(
    dayNumber: Int,
    totalDays: Int?,
    streak: Int,
    locale: String
  ) -> String {
    let en = isEnglish(locale)
    let dayText: String
    if let total = totalDays, total > 0 {
      dayText = en ? "Day \(dayNumber)/\(total)" : "Ngày \(dayNumber)/\(total)"
    } else {
      dayText = en ? "Day \(dayNumber)" : "Ngày \(dayNumber)"
    }
    let streakText = en ? "\(streak)d" : "Chuỗi \(streak) ngày"
    return "\(dayText) · \(streakText)"
  }

  public static func squadEntitySubtitle(
    doneCount: Int,
    memberCount: Int,
    dayNumber: Int,
    locale: String
  ) -> String {
    let en = isEnglish(locale)
    let total = max(memberCount, doneCount)
    if en {
      return "Day \(dayNumber) · \(doneCount)/\(total) today"
    }
    return "Ngày \(dayNumber) · \(doneCount)/\(total) hôm nay"
  }

  public static func archivedEntityFallbackSubtitle(locale: String) -> String {
    isEnglish(locale)
      ? "Falls back to Automatic when a pinned journey ends"
      : "Tự động chuyển sang hành trình đang hoạt động"
  }

  // MARK: - Lock Screen & Live Activity Copy

  public static func lockScreenRedactedTitle(locale: String) -> String {
    "Ourney"
  }

  public static func lockScreenRemaining(pending: Int, locale: String) -> String {
    let en = isEnglish(locale)
    if pending <= 0 {
      return en ? "All done today" : "Đã xong hôm nay"
    }
    return en ? "\(pending) left today" : "Còn \(pending) hành trình"
  }

  public static func lockScreenInline(streak: Int, pending: Int, locale: String) -> String {
    let en = isEnglish(locale)
    if pending <= 0 {
      return en ? "\(streak)d · All done" : "\(streak) ngày · Đã xong"
    }
    return en ? "\(streak)d · \(pending) left" : "\(streak) ngày · Còn \(pending)"
  }

  public static func liveActivityWindowLabel(atRisk: Bool, skinId: String, locale: String) -> String {
    let en = isEnglish(locale)
    if atRisk && skinId != "quiet" {
      return en ? "STREAK AT RISK" : "SẮP HẾT HẠN CHUỖI"
    }
    return en ? "CHECK-IN WINDOW" : "KHUNG GIỜ CHECK-IN"
  }

  public static func liveActivityCelebrationTitle(streak: Int, locale: String) -> String {
    let en = isEnglish(locale)
    return en ? "All checked in! Streak \(streak)" : "Đã hoàn thành! Chuỗi \(streak) ngày"
  }

  // MARK: - VoiceOver Full Card Announcements (§5.4)

  public static func todayVoiceOverLabel(
    journey: WidgetJourneyItem,
    phase: OurneyTimePhase,
    locale: String
  ) -> String {
    let en = isEnglish(locale)
    let status = phaseBadgeText(
      phase: phase,
      skinId: journey.skinId,
      streak: journey.currentStreak,
      locale: locale
    )
    if en {
      let action = journey.checkedInToday
        ? "Double tap to open journey."
        : "Double tap to open camera."
      return "\(journey.title), Day \(journey.dayNumber), \(journey.currentStreak) day streak, \(status). \(action)"
    } else {
      let action = journey.checkedInToday
        ? "Chạm hai lần để xem hành trình."
        : "Chạm hai lần để mở máy ảnh."
      return "\(journey.title), ngày \(journey.dayNumber), chuỗi \(journey.currentStreak) ngày, \(status). \(action)"
    }
  }

  public static func squadVoiceOverLabel(squad: WidgetSquadItem, locale: String) -> String {
    let en = isEnglish(locale)
    if en {
      return "\(squad.title), \(squad.doneCount) of \(squad.memberCount) checked in today."
    } else {
      return "\(squad.title), \(squad.doneCount) trên \(squad.memberCount) thành viên đã chụp hôm nay."
    }
  }

  public static func cycleJourneyVoiceOverLabel(
    currentIndex: Int,
    totalPending: Int,
    locale: String
  ) -> String {
    let en = isEnglish(locale)
    if en {
      return "Cycle next pending journey, \(currentIndex) of \(totalPending)"
    } else {
      return "Đổi sang hành trình chờ chụp tiếp theo, \(currentIndex) trên \(totalPending)"
    }
  }

  public static func dismissLiveActivityVoiceOverLabel(locale: String) -> String {
    isEnglish(locale) ? "Dismiss check-in reminder" : "Ẩn lời nhắc check-in hôm nay"
  }
}
