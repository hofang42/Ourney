import Foundation
import UIKit
import XCTest
@testable import Runner

final class WidgetSnapshotRolloverTests: XCTestCase {
  private let sampleJson = """
  {
    "schemaVersion": 1,
    "generatedAtUtc": "2026-11-24T10:00:00.000Z",
    "authState": "ready",
    "locale": "vi",
    "themeMode": "system",
    "privacy": {
      "photoMode": "smart",
      "redactLockScreenTitles": false,
      "liveActivityEnabled": true
    },
    "defaultJourneyId": "6f8c9a10-ielts",
    "totals": {
      "activeCount": 2,
      "completedTodayCount": 1,
      "pendingTodayCount": 1,
      "atRiskCount": 1,
      "bestActiveStreak": 21
    },
    "journeys": [
      {
        "id": "6f8c9a10-ielts",
        "title": "Tự học IELTS 30 ngày",
        "kind": "group",
        "skinId": "squad",
        "colorVariant": 0,
        "typeIcon": "type-study",
        "timezone": "Asia/Ho_Chi_Minh",
        "utcOffsetMinutes": 420,
        "pinned": true,
        "dayNumber": 15,
        "totalDays": 30,
        "currentStreak": 14,
        "bestStreak": 14,
        "checkedInToday": false,
        "atRisk": false,
        "eveningCueAtUtc": "2026-11-24T11:00:00.000Z",
        "streakAlertAtUtc": "2026-11-24T14:00:00.000Z",
        "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
        "reminderAtUtc": "2026-11-24T13:00:00.000Z",
        "heroThumbFile": null,
        "heroThumbBlurred": false,
        "weekStrip": [
          {"date": "2026-11-18", "day": 18, "label": "T4", "state": "done"},
          {"date": "2026-11-19", "day": 19, "label": "T5", "state": "done"},
          {"date": "2026-11-20", "day": 20, "label": "T6", "state": "done"},
          {"date": "2026-11-21", "day": 21, "label": "T7", "state": "done"},
          {"date": "2026-11-22", "day": 22, "label": "CN", "state": "done"},
          {"date": "2026-11-23", "day": 23, "label": "T2", "state": "done"},
          {"date": "2026-11-24", "day": 24, "label": "HN", "state": "today"}
        ]
      },
      {
        "id": "8a10b220-run",
        "title": "Chạy bộ sáng 5km",
        "kind": "solo",
        "skinId": "flexer",
        "colorVariant": 0,
        "typeIcon": "type-workout",
        "timezone": "Asia/Ho_Chi_Minh",
        "utcOffsetMinutes": 420,
        "pinned": false,
        "dayNumber": 21,
        "totalDays": 30,
        "currentStreak": 21,
        "bestStreak": 21,
        "checkedInToday": true,
        "atRisk": false,
        "eveningCueAtUtc": "2026-11-24T11:00:00.000Z",
        "streakAlertAtUtc": "2026-11-24T14:00:00.000Z",
        "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
        "heroThumbFile": "thumbs/a91f4c82b011e3d4.jpg",
        "heroThumbBlurred": false,
        "weekStrip": [
          {"date": "2026-11-18", "day": 18, "label": "T4", "state": "done"},
          {"date": "2026-11-19", "day": 19, "label": "T5", "state": "done"},
          {"date": "2026-11-20", "day": 20, "label": "T6", "state": "done"},
          {"date": "2026-11-21", "day": 21, "label": "T7", "state": "done"},
          {"date": "2026-11-22", "day": 22, "label": "CN", "state": "done"},
          {"date": "2026-11-23", "day": 23, "label": "T2", "state": "done"},
          {"date": "2026-11-24", "day": 24, "label": "HN", "state": "done"}
        ]
      }
    ],
    "squads": [
      {
        "journeyId": "6f8c9a10-ielts",
        "title": "Tự học IELTS 30 ngày",
        "skinId": "squad",
        "colorVariant": 0,
        "typeIcon": "type-study",
        "isCouple": false,
        "dayNumber": 15,
        "totalDays": 30,
        "doneCount": 1,
        "memberCount": 2,
        "meCheckedInToday": false,
        "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
        "members": [
          {
            "displayName": "Minh",
            "initial": "M",
            "avatarColorIndex": 3,
            "isMe": false,
            "checkedInToday": true,
            "streak": 14,
            "avatarFile": "thumbs/04c81e9a22f109bc.jpg",
            "todayThumbFile": "thumbs/77d21f0091ab34ef.jpg",
            "todayThumbBlurred": true
          },
          {
            "displayName": "Bạn",
            "initial": "B",
            "avatarColorIndex": 1,
            "isMe": true,
            "checkedInToday": false,
            "streak": 14
          }
        ]
      }
    ],
    "liveWindow": {
      "windowKey": "2026-11-24:6f8c9a10-ielts",
      "journeyId": "6f8c9a10-ielts",
      "journeyTitle": "Tự học IELTS 30 ngày",
      "skinId": "squad",
      "colorVariant": 0,
      "typeIcon": "type-study",
      "currentStreak": 14,
      "atRisk": true,
      "pendingCount": 1,
      "completedCount": 1,
      "totalActiveCount": 2,
      "windowStartUtc": "2026-11-24T12:30:00.000Z",
      "deadlineUtc": "2026-11-24T17:00:00.000Z"
    }
  }
  """

  func testDecodeFrozenContractAndVerifyPrivacyByOmission() throws {
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

    XCTAssertEqual(snapshot.schemaVersion, 1)
    XCTAssertEqual(snapshot.authState, "ready")
    XCTAssertEqual(snapshot.locale, "vi")
    XCTAssertEqual(snapshot.privacy.photoMode, "smart")
    XCTAssertFalse(snapshot.privacy.redactLockScreenTitles)
    XCTAssertTrue(snapshot.privacy.liveActivityEnabled)
    XCTAssertEqual(snapshot.journeys.count, 2)
    XCTAssertEqual(snapshot.squads.count, 1)
    XCTAssertEqual(snapshot.liveWindow?.windowKey, "2026-11-24:6f8c9a10-ielts")

    let reEncoded = try String(data: JSONEncoder().encode(snapshot), encoding: .utf8) ?? ""
    XCTAssertFalse(reEncoded.contains("metricValue"))
    XCTAssertFalse(reEncoded.contains("metricUnit"))
    XCTAssertFalse(reEncoded.contains("caption"))
  }

  func testTimePhasesAcrossDayEveningAndAtRisk() throws {
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
    let pending = try XCTUnwrap(snapshot.journeys.first(where: { $0.id == "6f8c9a10-ielts" }))
    let completed = try XCTUnwrap(snapshot.journeys.first(where: { $0.id == "8a10b220-run" }))

    let daytime = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T10:30:00.000Z"))
    let evening = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T11:30:00.000Z"))
    let urgent = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T14:30:00.000Z"))

    XCTAssertEqual(pending.phase(at: daytime), .daytime)
    XCTAssertEqual(pending.phase(at: evening), .eveningCue)
    XCTAssertEqual(pending.phase(at: urgent), .urgentAtRisk)
    XCTAssertEqual(completed.phase(at: daytime), .completed)
    XCTAssertEqual(completed.phase(at: urgent), .completed)
  }

  func testPostMidnightRolloverResetsCompletedAndBreaksMissedStreak() throws {
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

    // 2026-11-24T17:05:00.000Z is 00:05 on 2026-11-25 in Asia/Ho_Chi_Minh (UTC+7).
    let afterMidnight = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T17:05:00.000Z"))
    let rolled = snapshot.evaluated(at: afterMidnight)

    // 1. Journey that was NOT checked in before midnight ("6f8c9a10-ielts"):
    //    streak breaks to 0, dayNumber increments 15 -> 16, atRisk becomes false.
    let missedJourney = try XCTUnwrap(rolled.journeys.first(where: { $0.id == "6f8c9a10-ielts" }))
    XCTAssertFalse(missedJourney.checkedInToday)
    XCTAssertEqual(missedJourney.dayNumber, 16)
    XCTAssertEqual(missedJourney.currentStreak, 0)
    XCTAssertFalse(missedJourney.atRisk)
    XCTAssertEqual(missedJourney.weekStrip.count, 7)
    XCTAssertEqual(missedJourney.weekStrip[5].date, "2026-11-24")
    XCTAssertEqual(missedJourney.weekStrip[5].state, "missed")
    XCTAssertEqual(missedJourney.weekStrip[6].date, "2026-11-25")
    XCTAssertEqual(missedJourney.weekStrip[6].state, "today")

    // 2. Journey that WAS checked in before midnight ("8a10b220-run"):
    //    checkedInToday resets to false for the new day, dayNumber increments 21 -> 22,
    //    currentStreak survives at 21, atRisk is true, heroThumbFile clears.
    let survivedJourney = try XCTUnwrap(rolled.journeys.first(where: { $0.id == "8a10b220-run" }))
    XCTAssertFalse(survivedJourney.checkedInToday)
    XCTAssertEqual(survivedJourney.dayNumber, 22)
    XCTAssertEqual(survivedJourney.currentStreak, 21)
    XCTAssertTrue(survivedJourney.atRisk)
    XCTAssertNil(survivedJourney.heroThumbFile)
    XCTAssertEqual(survivedJourney.weekStrip[5].date, "2026-11-24")
    XCTAssertEqual(survivedJourney.weekStrip[5].state, "done")
    XCTAssertEqual(survivedJourney.weekStrip[6].date, "2026-11-25")
    XCTAssertEqual(survivedJourney.weekStrip[6].state, "today")

    // 3. Totals recomputed for the new day: 0 completed, 2 pending, bestActiveStreak 21.
    XCTAssertEqual(rolled.totals.activeCount, 2)
    XCTAssertEqual(rolled.totals.completedTodayCount, 0)
    XCTAssertEqual(rolled.totals.pendingTodayCount, 2)
    XCTAssertEqual(rolled.totals.atRiskCount, 1)
    XCTAssertEqual(rolled.totals.bestActiveStreak, 21)

    // 4. Squad rolled over: doneCount -> 0, meCheckedInToday -> false, member thumbs cleared.
    let rolledSquad = try XCTUnwrap(rolled.squads.first)
    XCTAssertEqual(rolledSquad.dayNumber, 16)
    XCTAssertEqual(rolledSquad.doneCount, 0)
    XCTAssertFalse(rolledSquad.meCheckedInToday)
    XCTAssertFalse(rolledSquad.members[0].checkedInToday)
    XCTAssertEqual(rolledSquad.members[0].streak, 14) // Minh checked in yesterday
    XCTAssertNil(rolledSquad.members[0].todayThumbFile)
    XCTAssertEqual(rolledSquad.members[1].streak, 0) // Self missed yesterday

    // 5. Live window expired at midnight deadline.
    XCTAssertNil(rolled.liveWindow)
  }

  func testMultiDayClosedAppRolloverBreaksAllStreaks() throws {
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

    // Two midnights later (2026-11-25T17:05:00.000Z = 00:05 on 2026-11-26 local):
    // Even the journey that was checked in on 2026-11-24 missed 2026-11-25, so its streak resets to 0.
    let twoMidnightsLater = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-25T17:05:00.000Z"))
    let rolled = snapshot.evaluated(at: twoMidnightsLater)

    for journey in rolled.journeys {
      XCTAssertFalse(journey.checkedInToday)
      XCTAssertEqual(journey.currentStreak, 0)
      XCTAssertFalse(journey.atRisk)
    }
    XCTAssertEqual(rolled.totals.bestActiveStreak, 0)
  }

  func testScheduledTimelineDatesReturnsFourDeterministicEntries() throws {
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))
    let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
    let now = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T10:00:00.000Z"))

    let dates = snapshot.scheduledTimelineDates(from: now)
    XCTAssertEqual(dates.count, 4)
    XCTAssertEqual(dates[0], now)
    XCTAssertEqual(dates[1], WidgetDateParser.parseISO8601("2026-11-24T11:00:00.000Z"))
    XCTAssertEqual(dates[2], WidgetDateParser.parseISO8601("2026-11-24T14:00:00.000Z"))
    XCTAssertEqual(dates[3], WidgetDateParser.parseISO8601("2026-11-24T17:00:00.000Z"))
  }

  func testCycleTodayJourneyAndBridgeAtomicWriteInTempDirectory() throws {
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("ourney_widget_tests_\(UUID().uuidString)", isDirectory: true)
    defer {
      try? FileManager.default.removeItem(at: tempRoot)
    }

    let bridge = OurneyWidgetBridge()
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))

    // First write should report changed = true.
    let firstWrite = bridge.writeSnapshotAndThumbs(
      snapshotData: data,
      thumbSpecs: [],
      overrideRootDirectory: tempRoot
    )
    XCTAssertTrue(firstWrite)

    // Duplicate write with identical payload should report changed = false (0 redundant reloads).
    let secondWrite = bridge.writeSnapshotAndThumbs(
      snapshotData: data,
      thumbSpecs: [],
      overrideRootDirectory: tempRoot
    )
    XCTAssertFalse(secondWrite)

    // Roll past midnight so both journeys are pending, then cycle between them via state.json.
    let afterMidnight = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T17:05:00.000Z"))
    let loaded = try XCTUnwrap(
      WidgetSnapshotStore.loadSnapshot(at: afterMidnight, rootDirectory: tempRoot)
    )
    XCTAssertEqual(loaded.selectedTodayJourney(state: WidgetInteractiveState())?.id, "6f8c9a10-ielts")

    let cycledState1 = WidgetSnapshotStore.cycleSelectedTodayJourney(
      at: afterMidnight,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(cycledState1.selectedTodayIndex, 1)
    XCTAssertEqual(loaded.selectedTodayJourney(state: cycledState1)?.id, "8a10b220-run")

    let cycledState2 = WidgetSnapshotStore.cycleSelectedTodayJourney(
      at: afterMidnight,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(cycledState2.selectedTodayIndex, 0)
    XCTAssertEqual(loaded.selectedTodayJourney(state: cycledState2)?.id, "6f8c9a10-ielts")

    // Dismiss window key persists in state.json.
    let dismissed = WidgetSnapshotStore.recordDismissedWindow(
      windowKey: "2026-11-24:6f8c9a10-ielts",
      at: afterMidnight,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(dismissed.dismissedWindowKey, "2026-11-24:6f8c9a10-ielts")
    XCTAssertEqual(dismissed.dismissedWindowDate, "2026-11-24")

    // Clear all removes snapshot_v1.json and state.json.
    bridge.clearAllFiles(overrideRootDirectory: tempRoot)
    XCTAssertNil(WidgetSnapshotStore.loadSnapshot(at: afterMidnight, rootDirectory: tempRoot))
  }

  func testDeepLinkQueryEscapesReservedCharactersAndSingleBlurStagingAndAbsentOptionalKeys() throws {
    let url = OurneyDeepLinks.capture(journeyId: "journey+1&mode=fast=true")
    XCTAssertEqual(url.absoluteString, "ourney://capture?journeyId=journey%2B1%26mode%3Dfast%3Dtrue")

    // (a) Verify OurneyWidgetBridge stages pre-blurred thumbnails under exact `thumbs/<id>.jpg`
    //     without `_blur` filename mutation or native CIGaussianBlur re-blurring.
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("ourney_widget_thumb_tests_\(UUID().uuidString)", isDirectory: true)
    defer {
      try? FileManager.default.removeItem(at: tempRoot)
    }
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    let sourceImageURL = tempRoot.appendingPathComponent("source_preblurred.jpg")
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48))
    let img = renderer.image { ctx in
      UIColor.systemOrange.setFill()
      ctx.fill(CGRect(x: 0, y: 0, width: 48, height: 48))
    }
    let jpegBytes = try XCTUnwrap(img.jpegData(compressionQuality: 0.85))
    try jpegBytes.write(to: sourceImageURL)

    // Minimal JSON with ABSENT optional keys (`defaultJourneyId`, `totalDays`, `reminderAtUtc`,
    // `avatarFile`, `todayThumbFile`, `liveWindow`) and a pre-blurred `heroThumbFile`.
    let minimalJson = """
    {
      "schemaVersion": 1,
      "generatedAtUtc": "2026-11-24T10:00:00.000Z",
      "authState": "ready",
      "locale": "vi",
      "themeMode": "system",
      "privacy": {
        "photoMode": "blurred",
        "redactLockScreenTitles": true,
        "liveActivityEnabled": true
      },
      "totals": {
        "activeCount": 1,
        "completedTodayCount": 1,
        "pendingTodayCount": 0,
        "atRiskCount": 0,
        "bestActiveStreak": 15
      },
      "journeys": [
        {
          "id": "open-ended-1",
          "title": "Đọc sách mỗi ngày",
          "kind": "solo",
          "skinId": "minimal",
          "colorVariant": 0,
          "typeIcon": "type-custom",
          "timezone": "Asia/Ho_Chi_Minh",
          "utcOffsetMinutes": 420,
          "pinned": true,
          "dayNumber": 15,
          "currentStreak": 15,
          "bestStreak": 15,
          "checkedInToday": true,
          "atRisk": false,
          "heroThumbFile": "thumbs/a91f4c82b011e3d4.jpg",
          "heroThumbBlurred": true
        }
      ],
      "squads": [
        {
          "journeyId": "open-ended-1",
          "title": "Đọc sách mỗi ngày",
          "skinId": "squad",
          "colorVariant": 0,
          "typeIcon": "type-study",
          "isCouple": false,
          "dayNumber": 15,
          "doneCount": 1,
          "memberCount": 1,
          "meCheckedInToday": true,
          "members": [
            {
              "displayName": "Minh",
              "initial": "M",
              "avatarColorIndex": 2,
              "isMe": true,
              "checkedInToday": true,
              "streak": 15
            }
          ]
        }
      ]
    }
    """

    let minimalData = try XCTUnwrap(minimalJson.data(using: .utf8))
    let decodedMinimal = try JSONDecoder().decode(WidgetSnapshot.self, from: minimalData)

    // (b) Verify absent optional keys decode cleanly to nil (open-ended journey totalDays == nil).
    XCTAssertNil(decodedMinimal.defaultJourneyId)
    XCTAssertNil(decodedMinimal.liveWindow)
    XCTAssertEqual(decodedMinimal.journeys.count, 1)
    XCTAssertNil(decodedMinimal.journeys[0].totalDays)
    XCTAssertNil(decodedMinimal.journeys[0].reminderAtUtc)
    XCTAssertEqual(decodedMinimal.journeys[0].dayNumber, 15)
    XCTAssertEqual(decodedMinimal.squads.count, 1)
    XCTAssertNil(decodedMinimal.squads[0].totalDays)
    XCTAssertNil(decodedMinimal.squads[0].members[0].avatarFile)
    XCTAssertNil(decodedMinimal.squads[0].members[0].todayThumbFile)
    XCTAssertFalse(decodedMinimal.squads[0].members[0].todayThumbBlurred)

    let bridge = OurneyWidgetBridge()
    let didWrite = bridge.writeSnapshotAndThumbs(
      snapshotData: minimalData,
      thumbSpecs: [
        [
          "id": "a91f4c82b011e3d4.jpg",
          "sourcePath": sourceImageURL.path,
          "maxSide": 320,
          "blur": true,
        ]
      ],
      overrideRootDirectory: tempRoot
    )
    XCTAssertTrue(didWrite)

    let resolvedExactURL = WidgetSnapshotStore.thumbURL(
      for: "thumbs/a91f4c82b011e3d4.jpg",
      rootDirectory: tempRoot
    )
    XCTAssertNotNil(resolvedExactURL)
    XCTAssertEqual(resolvedExactURL?.lastPathComponent, "a91f4c82b011e3d4.jpg")
    XCTAssertNil(
      WidgetSnapshotStore.thumbURL(
        for: "thumbs/a91f4c82b011e3d4_blur.jpg",
        rootDirectory: tempRoot
      )
    )

    // (c) Verify canonical redactLockScreenTitles precedence over legacy redactTitleOnLockScreen
    //     and fail-closed default when payload keys and cachedSnapshot are absent.
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactTitleOnLockScreen": false,
          "redactLockScreenTitles": true,
        ]
      )
    )
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactTitleOnLockScreen": false,
          "liveWindow": ["redactLockScreenTitles": true],
        ]
      )
    )
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "liveWindow": ["journeyId": "open-ended-1"],
          "privacy": ["redactLockScreenTitles": true],
        ]
      )
    )
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: ["redactTitleOnLockScreen": true]
      )
    )
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [:],
        cachedSnapshot: nil
      )
    )
    // Sensitive journeys are ALWAYS redacted on Lock Screen Live Activity even when
    // the user toggle is OFF (`redactLockScreenTitles: false`), while non-sensitive
    // journeys with the toggle OFF return `false`.
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactLockScreenTitles": false,
          "skinId": "quiet",
          "typeIcon": "type-weight",
        ]
      )
    )
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactLockScreenTitles": false,
          "isSensitive": true,
          "skinId": "minimal",
          "typeIcon": "type-custom",
        ]
      )
    )
    let sensitiveCachedSnap = WidgetSnapshot(
      authState: "ready",
      locale: "vi",
      privacy: WidgetPrivacySettings(
        photoMode: "smart",
        redactLockScreenTitles: false
      ),
      journeys: [
        WidgetJourneyItem(
          id: "solo-weight",
          title: "Giảm cân 60 ngày",
          skinId: "minimal",
          typeIcon: "type-custom",
          isSensitive: true
        ),
        WidgetJourneyItem(
          id: "solo-study",
          title: "Tự học IELTS",
          skinId: "squad",
          typeIcon: "type-study",
          isSensitive: false
        ),
      ],
      squads: []
    )
    XCTAssertTrue(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactLockScreenTitles": false,
          "journeyId": "solo-weight",
        ],
        cachedSnapshot: sensitiveCachedSnap
      )
    )
    XCTAssertFalse(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactLockScreenTitles": false,
          "skinId": "squad",
          "typeIcon": "type-study",
        ]
      )
    )
    XCTAssertFalse(
      OurneyWidgetBridge.resolveRedactLockScreenTitles(
        topDict: [
          "redactLockScreenTitles": false,
          "journeyId": "solo-study",
        ],
        cachedSnapshot: sensitiveCachedSnap
      )
    )

    // (d) Verify Lock Screen redacted title matches UI promise ("Ourney") and non-VI locales default to English.
    XCTAssertEqual(WidgetL10n.lockScreenRedactedTitle(locale: "vi"), "Ourney")
    XCTAssertEqual(WidgetL10n.lockScreenRedactedTitle(locale: "en"), "Ourney")
    XCTAssertFalse(WidgetL10n.isEnglish("vi"))
    XCTAssertTrue(WidgetL10n.isEnglish("en"))
    XCTAssertTrue(WidgetL10n.isEnglish("fr"))
    XCTAssertEqual(WidgetPreviewFixtures.sampleTodaySnapshot(locale: "en").locale, "en")
    XCTAssertEqual(WidgetPreviewFixtures.sampleTodaySnapshot(locale: "en").journeys.first?.title, "30-Day IELTS Study")
    XCTAssertEqual(WidgetPreviewFixtures.sampleTodaySnapshot(locale: "vi").locale, "vi")
    XCTAssertEqual(WidgetPreviewFixtures.sampleTodaySnapshot(locale: "vi").journeys.first?.title, "Tự học IELTS 30 ngày")
  }

  func testConfigurableWidgetEntityQueryAndSelectionFallback() throws {
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("ourney_widget_entity_tests_\(UUID().uuidString)", isDirectory: true)
    defer {
      try? FileManager.default.removeItem(at: tempRoot)
    }

    let now = try XCTUnwrap(WidgetDateParser.parseISO8601("2026-11-24T10:00:00.000Z"))

    // 1. Before snapshot_v1.json exists (Unsynced): suggestedEntities still returns ["auto"]
    //    and defaultResult returns "auto" ("Tự động (Đề xuất)" in VI / "Automatic (Recommended)" in EN).
    let unsyncedJourneysVi = WidgetSnapshotStore.suggestedJourneyEntityOptions(
      at: now,
      rootDirectory: tempRoot,
      fallbackLocale: "vi"
    )
    XCTAssertEqual(unsyncedJourneysVi.map(\.id), ["auto"])
    XCTAssertEqual(unsyncedJourneysVi.first?.title, "Tự động (Đề xuất)")
    XCTAssertEqual(
      WidgetSnapshotStore.defaultJourneyEntityOption(
        at: now,
        rootDirectory: tempRoot,
        fallbackLocale: "en"
      ).title,
      "Automatic (Recommended)"
    )

    // 2. Write sample snapshot_v1.json and verify suggestedJourneyEntityOptions & suggestedSquadEntityOptions.
    let bridge = OurneyWidgetBridge()
    let data = try XCTUnwrap(sampleJson.data(using: .utf8))
    XCTAssertTrue(
      bridge.writeSnapshotAndThumbs(
        snapshotData: data,
        thumbSpecs: [],
        overrideRootDirectory: tempRoot
      )
    )

    let journeyOptions = WidgetSnapshotStore.suggestedJourneyEntityOptions(
      at: now,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(journeyOptions.map(\.id), ["auto", "6f8c9a10-ielts", "8a10b220-run"])
    XCTAssertEqual(journeyOptions[1].title, "Tự học IELTS 30 ngày")
    XCTAssertEqual(journeyOptions[1].subtitle, "Ngày 15/30 · Chuỗi 14 ngày")
    XCTAssertEqual(journeyOptions[2].title, "Chạy bộ sáng 5km")
    XCTAssertEqual(journeyOptions[2].subtitle, "Ngày 21/30 · Chuỗi 21 ngày")

    let squadOptions = WidgetSnapshotStore.suggestedSquadEntityOptions(
      at: now,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(squadOptions.map(\.id), ["auto", "6f8c9a10-ielts"])
    XCTAssertEqual(squadOptions[1].title, "Tự học IELTS 30 ngày")
    XCTAssertEqual(squadOptions[1].subtitle, "Ngày 15 · 1/2 hôm nay")

    // 3. Entity lookup by IDs resolves "auto", active IDs, and returns a graceful fallback option
    //    for archived/deleted IDs so WidgetKit never shows a broken parameter row.
    let resolvedJourneys = WidgetSnapshotStore.journeyEntityOptions(
      for: ["auto", "8a10b220-run", "archived-journey-999"],
      at: now,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(resolvedJourneys.count, 3)
    XCTAssertEqual(resolvedJourneys[0].id, "auto")
    XCTAssertEqual(resolvedJourneys[1].id, "8a10b220-run")
    XCTAssertEqual(resolvedJourneys[1].title, "Chạy bộ sáng 5km")
    XCTAssertEqual(resolvedJourneys[2].id, "archived-journey-999")
    XCTAssertEqual(resolvedJourneys[2].title, "Tự động (Đề xuất)")

    let resolvedSquads = WidgetSnapshotStore.squadEntityOptions(
      for: ["auto", "6f8c9a10-ielts", "deleted-squad-999"],
      at: now,
      rootDirectory: tempRoot
    )
    XCTAssertEqual(resolvedSquads.count, 3)
    XCTAssertEqual(resolvedSquads[0].id, "auto")
    XCTAssertEqual(resolvedSquads[1].id, "6f8c9a10-ielts")
    XCTAssertEqual(resolvedSquads[2].id, "deleted-squad-999")
    XCTAssertEqual(resolvedSquads[2].title, "Tự động (Đề xuất)")

    // 4. Pinned selection overrides "auto" on Today, Streak, Squad, and Lock Screen,
    //    and falls back to "auto" when pinnedId is nil, "auto", or archived/deleted.
    let loaded = try XCTUnwrap(
      WidgetSnapshotStore.loadSnapshot(at: now, rootDirectory: tempRoot)
    )
    // In "auto" mode on Today, pending journey "6f8c9a10-ielts" is selected over completed "8a10b220-run".
    XCTAssertEqual(loaded.selectedTodayJourney(pinnedId: nil)?.id, "6f8c9a10-ielts")
    XCTAssertEqual(loaded.selectedTodayJourney(pinnedId: "auto")?.id, "6f8c9a10-ielts")
    XCTAssertFalse(loaded.isTodayJourneyPinned(nil))
    XCTAssertFalse(loaded.isTodayJourneyPinned("auto"))

    // Pinning completed journey "8a10b220-run" selects it directly and marks it pinned (hiding cycle pill).
    XCTAssertEqual(loaded.selectedTodayJourney(pinnedId: "8a10b220-run")?.id, "8a10b220-run")
    XCTAssertTrue(loaded.isTodayJourneyPinned("8a10b220-run"))

    // Archived/deleted pinnedId falls back to "auto" ("6f8c9a10-ielts") and unmarks isTodayJourneyPinned.
    XCTAssertEqual(loaded.selectedTodayJourney(pinnedId: "archived-journey-999")?.id, "6f8c9a10-ielts")
    XCTAssertFalse(loaded.isTodayJourneyPinned("archived-journey-999"))

    // Streak widget: defaultJourneyId is "6f8c9a10-ielts" in "auto", pinning "8a10b220-run" selects it,
    // and archived ID falls back to "auto".
    XCTAssertEqual(loaded.selectedStreakJourney(preferredId: "auto")?.id, "6f8c9a10-ielts")
    XCTAssertEqual(loaded.selectedStreakJourney(preferredId: "8a10b220-run")?.id, "8a10b220-run")
    XCTAssertEqual(loaded.selectedStreakJourney(preferredId: "archived-journey-999")?.id, "6f8c9a10-ielts")

    // Squad widget: pinning valid squad or falling back from deleted squad ID to "auto".
    XCTAssertEqual(loaded.selectedSquad(preferredId: "6f8c9a10-ielts")?.journeyId, "6f8c9a10-ielts")
    XCTAssertEqual(loaded.selectedSquad(preferredId: "deleted-squad-999")?.journeyId, "6f8c9a10-ielts")

    // 5. Legacy snapshot payload omitting "journeys" and "squads" decodes cleanly with empty arrays.
    let legacyJsonWithoutLists = """
    {
      "schemaVersion": 1,
      "generatedAtUtc": "2026-11-24T10:00:00.000Z",
      "authState": "ready",
      "locale": "vi"
    }
    """
    let legacyDecoded = try JSONDecoder().decode(
      WidgetSnapshot.self,
      from: try XCTUnwrap(legacyJsonWithoutLists.data(using: .utf8))
    )
    XCTAssertTrue(legacyDecoded.journeys.isEmpty)
    XCTAssertTrue(legacyDecoded.squads.isEmpty)
  }

  func testFourStateCardResolutionAndSoloOnlySquadAndLockScreenSensitivity() throws {
    // 1. Unsynced (snapshot == nil)
    XCTAssertEqual(WidgetSnapshot.resolveTodayCardState(snapshot: nil), .unsynced)
    XCTAssertEqual(WidgetSnapshot.resolveStreakCardState(snapshot: nil), .unsynced)
    XCTAssertEqual(WidgetSnapshot.resolveSquadCardState(snapshot: nil), .unsynced)
    XCTAssertEqual(OurneyDeepLinks.syncJourneys.absoluteString, "ourney://journeys?syncWidgets=1")
    XCTAssertEqual(OurneyDeepLinks.newJourney.absoluteString, "ourney://journeys/new")

    // 2. SignedOut (authState == "signedOut")
    let signedOutSnap = WidgetSnapshot(authState: "signedOut")
    XCTAssertEqual(WidgetSnapshot.resolveTodayCardState(snapshot: signedOutSnap), .signedOut)
    XCTAssertEqual(WidgetSnapshot.resolveStreakCardState(snapshot: signedOutSnap), .signedOut)
    XCTAssertEqual(WidgetSnapshot.resolveSquadCardState(snapshot: signedOutSnap), .signedOut)

    // 3. NoJourneys / NoSquads (signed in, 0 journeys)
    let emptyAccountSnap = WidgetSnapshot(authState: "ready", journeys: [], squads: [])
    XCTAssertEqual(WidgetSnapshot.resolveTodayCardState(snapshot: emptyAccountSnap), .noJourneys)
    XCTAssertEqual(WidgetSnapshot.resolveStreakCardState(snapshot: emptyAccountSnap), .noJourneys)
    XCTAssertEqual(WidgetSnapshot.resolveSquadCardState(snapshot: emptyAccountSnap), .noSquads)

    // 4. SoloOnly on Squad widget (signed in, 2 solo journeys, 0 squads)
    let soloWeight = WidgetJourneyItem(
      id: "solo-weight",
      title: "Giảm cân 60 ngày",
      kind: "solo",
      skinId: "quiet",
      typeIcon: "type-weight",
      isSensitive: true
    )
    let soloStudy = WidgetJourneyItem(
      id: "solo-study",
      title: "Học tiếng Anh",
      kind: "solo",
      skinId: "squad",
      typeIcon: "type-study",
      isSensitive: false
    )
    let soloOnlySnap = WidgetSnapshot(
      authState: "ready",
      locale: "vi",
      privacy: WidgetPrivacySettings(
        photoMode: "smart",
        redactLockScreenTitles: true
      ),
      journeys: [soloWeight, soloStudy],
      squads: []
    )
    XCTAssertEqual(
      WidgetSnapshot.resolveSquadCardState(snapshot: soloOnlySnap),
      .soloOnly(soloCount: 2)
    )
    XCTAssertEqual(
      WidgetL10n.soloOnlySquadSubtitle(soloCount: 2, locale: "vi"),
      "Bạn có 2 hành trình cá nhân — tạo nhóm mới hoặc dùng widget Hôm nay."
    )
    XCTAssertEqual(
      WidgetL10n.soloOnlySquadSubtitle(soloCount: 1, locale: "en"),
      "You have 1 solo journey — start or join a Squad, or use the Today widget."
    )

    // 5. Fail-closed Lock Screen title redaction (§B.5):
    //    (a) When `redactLockScreenTitles == true` and `explicitRedactLockScreenTitles == nil`
    //        (current Dart `snapshot_v1.json` wire format), ALL journeys redact to `"Ourney"`
    //        so the user's "Hide journey titles on Lock Screen" toggle is always respected.
    XCTAssertTrue(soloOnlySnap.shouldRedactLockScreenTitle(for: soloWeight))
    XCTAssertTrue(soloOnlySnap.shouldRedactLockScreenTitle(for: soloStudy))
    XCTAssertTrue(soloOnlySnap.shouldRedactLockScreenTitle(for: nil))

    //    (b) When `redactLockScreenTitles == false` and `explicitRedactLockScreenTitles == nil`,
    //        sensitive journeys (`isEffectiveSensitiveJourney`: `isSensitive`, `quiet`, `type-weight`)
    //        still fail-closed to `"Ourney"`, while non-sensitive journeys display their title.
    let implicitWeightWithoutFlag = WidgetJourneyItem(
      id: "legacy-weight",
      title: "Giảm cân 30 ngày",
      kind: "solo",
      skinId: "quiet",
      typeIcon: "type-weight",
      isSensitive: false
    )
    let unredactedToggleSnap = WidgetSnapshot(
      authState: "ready",
      locale: "vi",
      privacy: WidgetPrivacySettings(
        photoMode: "smart",
        redactLockScreenTitles: false
      ),
      journeys: [soloWeight, implicitWeightWithoutFlag, soloStudy],
      squads: []
    )
    XCTAssertTrue(unredactedToggleSnap.shouldRedactLockScreenTitle(for: soloWeight))
    XCTAssertTrue(unredactedToggleSnap.shouldRedactLockScreenTitle(for: implicitWeightWithoutFlag))
    XCTAssertFalse(unredactedToggleSnap.shouldRedactLockScreenTitle(for: soloStudy))

    //    (c) When `privacy` or `redactLockScreenTitles` is omitted in JSON, `WidgetPrivacySettings`
    //        defaults `redactLockScreenTitles` to `true` (fail-closed).
    let omittedPrivacyJson = """
    {
      "schemaVersion": 1,
      "generatedAtUtc": "2026-11-24T10:00:00.000Z",
      "authState": "ready",
      "locale": "vi",
      "journeys": [
        {
          "id": "quiet-1",
          "title": "Giảm cân",
          "skinId": "quiet",
          "typeIcon": "type-weight"
        }
      ]
    }
    """
    let omittedPrivacySnap = try JSONDecoder().decode(
      WidgetSnapshot.self,
      from: try XCTUnwrap(omittedPrivacyJson.data(using: .utf8))
    )
    XCTAssertTrue(omittedPrivacySnap.privacy.redactLockScreenTitles)
    XCTAssertTrue(omittedPrivacySnap.shouldRedactLockScreenTitle(for: omittedPrivacySnap.journeys.first))
    XCTAssertTrue(omittedPrivacySnap.shouldRedactLockScreenTitle(for: soloStudy))

    //    (d) Explicit `explicitRedactLockScreenTitles` override (`true` or `false`) is honored when present.
    let forcedRedactSnap = WidgetSnapshot(
      authState: "ready",
      locale: "vi",
      privacy: WidgetPrivacySettings(
        photoMode: "smart",
        redactLockScreenTitles: false,
        explicitRedactLockScreenTitles: true
      ),
      journeys: [soloWeight, soloStudy],
      squads: []
    )
    XCTAssertTrue(forcedRedactSnap.shouldRedactLockScreenTitle(for: soloStudy))

    let explicitOptOutSnap = WidgetSnapshot(
      authState: "ready",
      locale: "vi",
      privacy: WidgetPrivacySettings(
        photoMode: "smart",
        redactLockScreenTitles: true,
        explicitRedactLockScreenTitles: false
      ),
      journeys: [soloWeight, soloStudy],
      squads: []
    )
    XCTAssertTrue(explicitOptOutSnap.shouldRedactLockScreenTitle(for: soloWeight))
    XCTAssertFalse(explicitOptOutSnap.shouldRedactLockScreenTitle(for: soloStudy))

    // 6. Bridge write outcome & capabilities
    let bridge = OurneyWidgetBridge()
    let caps = bridge.currentCapabilities()
    XCTAssertNotNil(caps["appGroupAvailable"] as? Bool)
    XCTAssertEqual(caps["appGroup"] as? Bool, caps["appGroupAvailable"] as? Bool)

    let blockingFileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("ourney_blocking_file_\(UUID().uuidString)")
    defer {
      try? FileManager.default.removeItem(at: blockingFileURL)
    }
    try Data("x".utf8).write(to: blockingFileURL)
    let failedOutcome = bridge.writeSnapshotAndThumbsOutcome(
      snapshotData: try XCTUnwrap(sampleJson.data(using: .utf8)),
      thumbSpecs: [],
      overrideRootDirectory: blockingFileURL.appendingPathComponent("nested", isDirectory: true)
    )
    XCTAssertFalse(failedOutcome.succeeded)
    XCTAssertFalse(failedOutcome.didChange)
  }
}
