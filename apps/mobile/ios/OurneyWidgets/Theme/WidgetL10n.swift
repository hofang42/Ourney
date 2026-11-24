import Foundation
import SwiftUI

/// Explicit Vietnamese (`vi` default) and English (`en`) localization helper for Ourney widgets
/// and Live Activities (§5.2).
/// Resolves `snapshot.locale` first so toggling language inside Ourney Settings immediately
/// updates every widget and Live Activity without restarting iOS.
public enum WidgetL10n {
  public static func isEnglish(_ locale: String?) -> Bool {
    if let raw = locale?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
      return raw.lowercased().hasPrefix("en")
    }
    let preferred = Locale.preferredLanguages.first ?? "vi"
    return preferred.lowercased().hasPrefix("en")
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

  // MARK: - Empty States (Including Free Apple ID Sideload Fallback — O2)

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

  // MARK: - Lock Screen & Live Activity Copy

  public static func lockScreenRedactedTitle(locale: String) -> String {
    isEnglish(locale) ? "Ourney Journey" : "Hành trình Ourney"
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
