package com.hofang42.ourney.widgets

import androidx.datastore.preferences.core.mutablePreferencesOf
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.time.Instant

class WidgetSnapshotStoreTest {
    @Test
    fun streakFlagsAcceptLegacyBooleanRepresentations() {
        for (truthy in listOf<Any>(true, "true", 1, "1")) {
            val json = org.json.JSONObject().put("id", "retold")
                .put("showStreak", truthy).put("streakCheckedInToday", truthy)
            val journey = WidgetJourneyItem.fromJson(json)
            assertTrue(journey.showStreak)
            assertTrue(journey.streakCheckedInToday)
        }
        for (falsy in listOf<Any>(false, "false", 0, "0")) {
            val json = org.json.JSONObject().put("id", "retold")
                .put("showStreak", falsy).put("streakCheckedInToday", falsy)
            val journey = WidgetJourneyItem.fromJson(json)
            assertFalse(journey.showStreak)
            assertFalse(journey.streakCheckedInToday)
        }
        val legacy = WidgetJourneyItem.fromJson(org.json.JSONObject("""{"id":"old","checkedInToday":1}"""))
        assertTrue(legacy.showStreak)
        assertTrue(legacy.streakCheckedInToday)
    }


    @Test
    fun retoldLibraryPhotoDoesNotPreserveCameraStreakAtMidnight() {
        val json = org.json.JSONObject("""{
          "id":"retold", "currentStreak":1, "bestStreak":1,
          "checkedInToday":true, "streakCheckedInToday":false,
          "showStreak":false, "midnightRolloverUtc":"2026-11-24T17:00:00Z"
        }""")
        val journey = WidgetJourneyItem.fromJson(json)
        assertFalse(journey.showStreak)
        assertTrue(journey.checkedInToday)
        assertFalse(journey.streakCheckedInToday)
        val rolled = journey.evaluateAt(Instant.parse("2026-11-24T17:05:00Z").toEpochMilli())
        assertEquals(0, rolled.currentStreak)
        assertFalse(rolled.atRisk)
        val legacy = WidgetJourneyItem.fromJson(org.json.JSONObject("""{"id":"old","checkedInToday":true}"""))
        assertTrue(legacy.showStreak)
        assertTrue(legacy.streakCheckedInToday)
    }

    @get:Rule
    val tempFolder = TemporaryFolder()

    private val sampleSnapshotJson = """
        {
          "schemaVersion": 1,
          "generatedAtUtc": "2026-11-24T11:55:00.000Z",
          "authState": "ready",
          "locale": "vi",
          "themeMode": "system",
          "privacy": {
            "photoMode": "smart",
            "redactLockScreenTitles": false,
            "liveActivityEnabled": true
          },
          "defaultJourneyId": "6f8c9a10-0001",
          "totals": {
            "activeCount": 2,
            "completedTodayCount": 1,
            "pendingTodayCount": 1,
            "atRiskCount": 0,
            "bestActiveStreak": 14
          },
          "journeys": [
            {
              "id": "6f8c9a10-0001",
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
              "heroThumbFile": "thumbs/a91f4c82b011e3d4.jpg",
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
              "id": "6f8c9a10-0002",
              "title": "Chạy bộ buổi sáng",
              "kind": "solo",
              "skinId": "flexer",
              "colorVariant": 1,
              "typeIcon": "type-workout",
              "timezone": "Asia/Ho_Chi_Minh",
              "utcOffsetMinutes": 420,
              "pinned": false,
              "dayNumber": 10,
              "totalDays": 30,
              "currentStreak": 10,
              "bestStreak": 12,
              "checkedInToday": true,
              "atRisk": false,
              "eveningCueAtUtc": "2026-11-24T11:00:00.000Z",
              "streakAlertAtUtc": "2026-11-24T14:00:00.000Z",
              "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
              "reminderAtUtc": null,
              "heroThumbFile": "thumbs/b82e5d93c122f4e5.jpg",
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
              "journeyId": "6f8c9a10-0001",
              "title": "Tự học IELTS 30 ngày",
              "skinId": "squad",
              "colorVariant": 0,
              "typeIcon": "type-study",
              "isCouple": false,
              "dayNumber": 15,
              "totalDays": 30,
              "doneCount": 3,
              "memberCount": 5,
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
                }
              ]
            }
          ],
          "liveWindow": {
            "windowKey": "2026-11-24:6f8c9a10-0001",
            "journeyId": "6f8c9a10-0001",
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
    """.trimIndent()

    @Test
    fun `parses snapshot_v1 json contract and evaluates pre-midnight streak alert`() {
        val store = WidgetSnapshotStore(tempFolder.newFolder("ourney_widgets"))
        val write1 = store.writeSnapshotAtomically(sampleSnapshotJson)
        assertTrue(write1.success)
        assertTrue(write1.changed)

        // Duplicate write with identical JSON should report changed = false (0 redundant reloads).
        val write2 = store.writeSnapshotAtomically(sampleSnapshotJson)
        assertTrue(write2.success)
        assertFalse(write2.changed)

        // Evaluate at 21:05 local (14:05 UTC, after streakAlertAtUtc = 14:00 UTC)
        val at2105Utc = Instant.parse("2026-11-24T14:05:00.000Z").toEpochMilli()
        val snapshot = store.readSnapshot(at2105Utc)
        assertNotNull(snapshot)
        snapshot!!

        assertEquals(1, snapshot.schemaVersion)
        assertEquals("vi", snapshot.locale)
        assertEquals("smart", snapshot.privacy.photoMode)
        assertEquals(2, snapshot.totals.activeCount)
        assertEquals(1, snapshot.totals.completedTodayCount)
        assertEquals(1, snapshot.totals.pendingTodayCount)
        assertEquals(1, snapshot.totals.atRiskCount)

        val ielts = snapshot.journeys.first { it.id == "6f8c9a10-0001" }
        assertTrue("Unchecked streak after 21:00 must escalate to atRisk", ielts.atRisk)
        assertTrue(ielts.isEveningCueActive(at2105Utc))
        assertTrue(ielts.isStreakAlertActive(at2105Utc))

        // Before 18:00 local (10:00 UTC), neither evening cue nor 21:00 streak alert is active
        val at1700Local = Instant.parse("2026-11-24T10:00:00.000Z").toEpochMilli()
        val morningSnapshot = store.readSnapshot(at1700Local)!!
        val morningIelts = morningSnapshot.journeys.first { it.id == "6f8c9a10-0001" }
        assertFalse(morningIelts.isEveningCueActive(at1700Local))
        assertFalse(morningIelts.isStreakAlertActive(at1700Local))

        // Between 18:00 and 21:00 local (12:00 UTC = 19:00 local), evening cue is active but streak alert is not
        val at1900Local = Instant.parse("2026-11-24T12:00:00.000Z").toEpochMilli()
        val eveningSnapshot = store.readSnapshot(at1900Local)!!
        val eveningIelts = eveningSnapshot.journeys.first { it.id == "6f8c9a10-0001" }
        assertTrue(eveningIelts.isEveningCueActive(at1900Local))
        assertFalse(eveningIelts.isStreakAlertActive(at1900Local))
    }

    @Test
    fun `decodes Couple slot IDs and preserves them through rollover`() {
        val squad = WidgetSnapshot.fromJson(
            """
            {"schemaVersion":1,"squads":[{
              "journeyId":"couple","isCouple":true,"memberCount":1,"doneCount":1,
              "midnightRolloverUtc":"2026-11-24T17:00:00Z",
              "members":[
                {"slotId":"owner","displayName":"Minh","checkedInToday":true,
                 "todayThumbBlurred":true,"todayThumbFile":"thumbs/owner.jpg"},
                {"slotId":"vacant","isVacant":true}
              ]
            }]}
            """.trimIndent(),
        ).squads.single()
        assertEquals(listOf("owner", "vacant"), squad.coupleSlots.map { it.slotId })
        assertTrue(squad.coupleSlots.last().isVacant)
        assertTrue(squad.copy(members = squad.members.take(1)).coupleSlots.last().isVacant)

        val rolled = squad.evaluateAt(Instant.parse("2026-11-24T17:00:00Z").toEpochMilli())
        assertEquals(squad.coupleSlots.map { it.slotId }, rolled.coupleSlots.map { it.slotId })
        assertFalse(rolled.coupleSlots.first().checkedInToday)
        assertFalse(rolled.coupleSlots.first().todayThumbBlurred)
        assertNull(rolled.coupleSlots.first().todayThumbFile)
    }

    @Test
    fun `evaluates post-midnight rollover natively for completed and missed journeys`() {
        val store = WidgetSnapshotStore(tempFolder.newFolder("ourney_widgets_rollover"))
        store.writeSnapshotAtomically(sampleSnapshotJson)

        // Evaluate 5 minutes after midnight rollover (17:05 UTC)
        val postMidnightUtc = Instant.parse("2026-11-24T17:05:00.000Z").toEpochMilli()
        val rolled = store.readSnapshot(postMidnightUtc)!!

        // Journey 1 (IELTS) was NOT checked in before midnight -> streak resets to 0
        val missedJourney = rolled.journeys.first { it.id == "6f8c9a10-0001" }
        assertEquals(16, missedJourney.dayNumber)
        assertEquals(0, missedJourney.currentStreak)
        assertFalse(missedJourney.checkedInToday)
        assertFalse(missedJourney.atRisk)
        assertEquals("missed", missedJourney.weekStrip[5].state)
        assertEquals("T3", missedJourney.weekStrip[5].label)
        assertEquals("today", missedJourney.weekStrip[6].state)
        assertEquals("HN", missedJourney.weekStrip[6].label)

        // Journey 2 (Running) WAS checked in before midnight -> streak 10 survives, unchecked for new day
        val survivedJourney = rolled.journeys.first { it.id == "6f8c9a10-0002" }
        assertEquals(11, survivedJourney.dayNumber)
        assertEquals(10, survivedJourney.currentStreak)
        assertFalse(survivedJourney.checkedInToday)
        assertTrue(survivedJourney.atRisk)
        assertFalse("00:05 morning should stay calm before 21:00", survivedJourney.isStreakAlertActive(postMidnightUtc))
        assertEquals("done", survivedJourney.weekStrip[5].state)
        assertEquals("T3", survivedJourney.weekStrip[5].label)
        assertEquals("today", survivedJourney.weekStrip[6].state)
        assertEquals("HN", survivedJourney.weekStrip[6].label)

        // Squad resets daily counts and clears stale todayThumbFile after midnight
        val squad = rolled.squads.first()
        assertEquals(16, squad.dayNumber)
        assertEquals(0, squad.doneCount)
        assertFalse(squad.meCheckedInToday)
        assertFalse(squad.members.first().checkedInToday)
        assertNull(squad.members.first().todayThumbFile)

        // Live window expires after deadlineUtc
        assertNull(rolled.liveWindow)
        assertEquals(0, rolled.totals.completedTodayCount)
        assertEquals(2, rolled.totals.pendingTodayCount)
    }

    @Test
    fun `cycles pending journeys and persists state and orphan thumb cleanup`() {
        val root = tempFolder.newFolder("ourney_widgets_state")
        val store = WidgetSnapshotStore(root)
        store.writeSnapshotAtomically(sampleSnapshotJson)

        // Post-midnight both journeys are pending; cycleTodayJourney alternates between them
        val postMidnightUtc = Instant.parse("2026-11-24T17:05:00.000Z").toEpochMilli()
        val rolled = store.readSnapshot(postMidnightUtc)!!

        val firstPick = rolled.selectTodayJourney(store.readState())
        assertEquals("6f8c9a10-0001", firstPick?.id)

        val nextState = store.cycleTodayJourney()
        assertEquals(1, nextState.selectedTodayIndex)
        val secondPick = rolled.selectTodayJourney(nextState)
        assertEquals("6f8c9a10-0002", secondPick?.id)

        // Mark window dismissed
        val dismissedState = store.markWindowDismissed("2026-11-24:6f8c9a10-0001", postMidnightUtc)
        assertEquals("2026-11-24:6f8c9a10-0001", dismissedState.dismissedWindowKey)

        // Thumbnail orphan pruning & path traversal defense
        assertNull(WidgetSnapshotStore.sanitizeFileName("../secret.jpg"))
        assertNull(WidgetSnapshotStore.sanitizeFileName(".."))
        assertEquals("a91f4c82b011e3d4.jpg", WidgetSnapshotStore.sanitizeFileName("a91f4c82b011e3d4.jpg"))

        val srcThumb = File(root, "source_thumb.jpg").apply {
            writeBytes(byteArrayOf(0x11, 0x22, 0x33, 0x44))
        }
        val preBlurredThumb = File(root, "pre_blurred_from_dart.jpg").apply {
            writeBytes(byteArrayOf(0x55, 0x66, 0x77, 0x7F))
        }
        val orphanFile = File(store.thumbsDir.apply { mkdirs() }, "orphan_old.jpg").apply {
            writeBytes(ByteArray(16) { 2 })
        }
        assertTrue(orphanFile.exists())

        store.syncThumbs(
            specs = listOf(
                ThumbSpec(
                    id = "a91f4c82b011e3d4.jpg",
                    sourcePath = srcThumb.absolutePath,
                    maxSide = 320,
                    blur = false,
                ),
                ThumbSpec(
                    id = "77d21f0091ab34ef.jpg",
                    sourcePath = preBlurredThumb.absolutePath,
                    maxSide = 160,
                    blur = true,
                ),
            ),
            referencedRelPaths = rolled.referencedThumbPaths(),
        )
        assertFalse("Orphan thumb must be swept", orphanFile.exists())
        assertNotNull(store.resolveThumbFile("thumbs/a91f4c82b011e3d4.jpg"))
        val stagedPreBlurred = store.resolveThumbFile("thumbs/77d21f0091ab34ef.jpg")
        assertNotNull(
            "Pre-blurred thumbnail from Dart must be staged without native re-blurring",
            stagedPreBlurred,
        )
        assertTrue(
            "Pre-blurred bytes from Dart must not be re-blurred on the native side",
            stagedPreBlurred!!.readBytes().contentEquals(preBlurredThumb.readBytes()),
        )

        // Verify WidgetLiveWindow.fromMap handles both flat and nested liveWindow maps
        val nestedWindow = WidgetLiveWindow.fromMap(
            mapOf(
                "liveWindow" to mapOf(
                    "windowKey" to "2026-11-24:6f8c9a10-0001",
                    "journeyId" to "6f8c9a10-0001",
                    "journeyTitle" to "IELTS",
                    "deadlineUtc" to "2026-11-24T17:00:00.000Z",
                    "pendingCount" to 1,
                ),
                "celebrateAndDismiss" to true,
            ),
        )
        assertEquals("6f8c9a10-0001", nestedWindow.journeyId)
        assertTrue(nestedWindow.celebrateAndDismiss)

        // ClearAll wipes snapshot, state, and thumbs
        assertTrue(store.clearAll())
        assertNull(store.readSnapshot(postMidnightUtc))
        assertEquals(0, store.readState().selectedTodayIndex)
    }

    @Test
    fun `handles absent optional keys explicit nulls open-ended journeys and redaction aliases`() {
        val openEndedSnapshotJson = """
            {
              "schemaVersion": 1,
              "generatedAtUtc": "2026-11-24T11:55:00.000Z",
              "authState": "ready",
              "locale": "en",
              "themeMode": "dark",
              "privacy": {
                "photoMode": "smart",
                "redactTitleOnLockScreen": true
              },
              "totals": {
                "activeCount": 2,
                "completedTodayCount": 1,
                "pendingTodayCount": 1,
                "atRiskCount": 0,
                "bestActiveStreak": 30
              },
              "journeys": [
                {
                  "id": "open-ended-1",
                  "title": "Daily Reading",
                  "kind": "solo",
                  "skinId": "minimal",
                  "colorVariant": 0,
                  "typeIcon": "type-custom",
                  "timezone": "Asia/Ho_Chi_Minh",
                  "utcOffsetMinutes": 420,
                  "pinned": true,
                  "dayNumber": 30,
                  "currentStreak": 30,
                  "bestStreak": 30,
                  "checkedInToday": true,
                  "atRisk": false,
                  "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
                  "heroThumbBlurred": false,
                  "weekStrip": [
                    {"date": "2026-11-24", "day": 24, "label": "TD", "state": "done"}
                  ]
                },
                {
                  "id": "explicit-nulls-2",
                  "title": "Weight Transformation",
                  "kind": "solo",
                  "skinId": "quiet",
                  "colorVariant": 0,
                  "typeIcon": "type-weight",
                  "timezone": "Asia/Ho_Chi_Minh",
                  "utcOffsetMinutes": 420,
                  "pinned": false,
                  "dayNumber": 45,
                  "totalDays": null,
                  "currentStreak": 12,
                  "bestStreak": 20,
                  "checkedInToday": true,
                  "atRisk": false,
                  "eveningCueAtUtc": null,
                  "streakAlertAtUtc": null,
                  "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
                  "reminderAtUtc": null,
                  "heroThumbFile": null,
                  "heroThumbBlurred": true
                }
              ],
              "squads": [
                {
                  "journeyId": "open-squad-1",
                  "title": "Open Study Squad",
                  "skinId": "squad",
                  "colorVariant": 0,
                  "typeIcon": "type-study",
                  "isCouple": false,
                  "dayNumber": 30,
                  "doneCount": 1,
                  "memberCount": 2,
                  "meCheckedInToday": true,
                  "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
                  "members": [
                    {
                      "displayName": "Lan",
                      "initial": "L",
                      "avatarColorIndex": 1,
                      "isMe": true,
                      "checkedInToday": true,
                      "streak": 30
                    },
                    {
                      "displayName": "Binh",
                      "initial": "B",
                      "avatarColorIndex": 2,
                      "isMe": false,
                      "checkedInToday": false,
                      "streak": 5,
                      "avatarFile": null,
                      "todayThumbFile": null
                    }
                  ]
                }
              ]
            }
        """.trimIndent()

        val store = WidgetSnapshotStore(tempFolder.newFolder("ourney_widgets_contract"))
        val writeRes = store.writeSnapshotAtomically(openEndedSnapshotJson)
        assertTrue(writeRes.success)

        val preMidnightUtc = Instant.parse("2026-11-24T12:00:00.000Z").toEpochMilli()
        val snapshot = store.readSnapshot(preMidnightUtc)!!

        // Absent optional top-level keys must decode to null, never literal "null"
        assertNull(snapshot.defaultJourneyId)
        assertNull(snapshot.liveWindow)
        assertTrue(
            "privacy must accept redactTitleOnLockScreen when redactLockScreenTitles is absent",
            snapshot.privacy.redactLockScreenTitles,
        )

        val openJourney = snapshot.journeys.first { it.id == "open-ended-1" }
        assertNull("Absent totalDays must represent an open-ended journey (not default to 30)", openJourney.totalDays)
        assertTrue(openJourney.isOpenEnded)
        assertNull(openJourney.eveningCueAtUtc)
        assertNull(openJourney.streakAlertAtUtc)
        assertNull(openJourney.reminderAtUtc)
        assertNull(openJourney.heroThumbFile)

        val nullJourney = snapshot.journeys.first { it.id == "explicit-nulls-2" }
        assertNull("Explicit null totalDays must decode as null (not 30)", nullJourney.totalDays)
        assertTrue(nullJourney.isOpenEnded)
        assertNull("Explicit null reminderAtUtc must never become literal \"null\"", nullJourney.reminderAtUtc)
        assertNull("Explicit null heroThumbFile must never become literal \"null\"", nullJourney.heroThumbFile)

        val openSquad = snapshot.squads.first()
        assertNull("Absent squad totalDays must decode as null (not 30)", openSquad.totalDays)
        assertTrue(openSquad.isOpenEnded)
        assertNull(openSquad.members[0].avatarFile)
        assertNull(openSquad.members[0].todayThumbFile)
        assertNull(openSquad.members[1].avatarFile)
        assertNull(openSquad.members[1].todayThumbFile)
        assertTrue("No null/absent thumb paths may be added to referencedThumbPaths", snapshot.referencedThumbPaths().isEmpty())

        // Post-midnight rollover on Day 30 open-ended journey & squad must advance to Day 31 (NOT clamp to 30)
        val postMidnightUtc = Instant.parse("2026-11-24T17:05:00.000Z").toEpochMilli()
        val rolled = store.readSnapshot(postMidnightUtc)!!
        val rolledOpenJourney = rolled.journeys.first { it.id == "open-ended-1" }
        assertEquals("Open-ended journey on Day 30 must advance to Day 31 after midnight", 31, rolledOpenJourney.dayNumber)
        assertNull(rolledOpenJourney.totalDays)

        val rolledNullJourney = rolled.journeys.first { it.id == "explicit-nulls-2" }
        assertEquals("Open-ended journey on Day 45 must advance to Day 46 after midnight", 46, rolledNullJourney.dayNumber)

        val rolledOpenSquad = rolled.squads.first()
        assertEquals("Open-ended squad on Day 30 must advance to Day 31 after midnight", 31, rolledOpenSquad.dayNumber)
        assertNull(rolledOpenSquad.totalDays)

        // State JSON with absent optional keys must decode to null, never "null"
        val minimalState = WidgetMutableState.fromJson("""{"selectedTodayIndex": 2}""")
        assertEquals(2, minimalState.selectedTodayIndex)
        assertNull(minimalState.dismissedWindowKey)
        assertNull(minimalState.dismissedWindowDate)

        // Live Activity redaction key resolution: spec key `redactLockScreenTitles` + backward-compat `redactTitleOnLockScreen`
        assertTrue(
            CheckInLiveUpdateManager.resolveRedactLockScreenTitles(
                mapOf("redactLockScreenTitles" to true),
                snapshot = null,
            ),
        )
        assertTrue(
            CheckInLiveUpdateManager.resolveRedactLockScreenTitles(
                mapOf("redactTitleOnLockScreen" to true),
                snapshot = null,
            ),
        )
        assertFalse(
            "Spec key redactLockScreenTitles must take precedence when both keys are present",
            CheckInLiveUpdateManager.resolveRedactLockScreenTitles(
                mapOf(
                    "redactLockScreenTitles" to false,
                    "redactTitleOnLockScreen" to true,
                ),
                snapshot = snapshot,
            ),
        )
        assertTrue(
            "Falls back to snapshot.privacy.redactLockScreenTitles when absent from args",
            CheckInLiveUpdateManager.resolveRedactLockScreenTitles(
                emptyMap<String, Any?>(),
                snapshot = snapshot,
            ),
        )
        assertTrue(
            "Sensitive journey must always redact on Lock Screen even when redactLockScreenTitles is false",
            CheckInLiveUpdateManager.resolveRedactLockScreenTitles(
                mapOf(
                    "redactLockScreenTitles" to false,
                    "isSensitive" to true,
                ),
                snapshot = snapshot,
            ),
        )
        assertTrue(
            "Implicitly sensitive weight journey must always redact on Lock Screen even when redactLockScreenTitles is false",
            CheckInLiveUpdateManager.resolveRedactLockScreenTitles(
                mapOf(
                    "redactLockScreenTitles" to false,
                    "journeyId" to "explicit-nulls-2",
                ),
                snapshot = snapshot,
            ),
        )
    }

    @Test
    fun `handles missing or corrupt snapshot file gracefully and verifies skin palettes`() {
        val root = tempFolder.newFolder("ourney_widgets_corrupt")
        val store = WidgetSnapshotStore(root)

        assertNull(store.readSnapshot())
        store.snapshotFile.writeText("{not valid json")
        assertNull(store.readSnapshot())
        assertFalse(store.writeSnapshotAtomically("{broken").success)

        // Verify OurneyGlanceTheme skin overrides and WCAG contrast
        val quietLight = OurneyGlanceTheme.skinPalette("quiet", 0, isDark = false)
        assertEquals(1.5f, quietLight.borderWidthDp)

        val minimalDarkV1 = OurneyGlanceTheme.skinPalette("minimal", 1, isDark = true)
        assertEquals(0xFFE4E4E7.toInt(), minimalDarkV1.button)
        assertEquals(0xFF18181A.toInt(), minimalDarkV1.buttonLabel)

        for (skinId in listOf("quiet", "squad", "memory", "couple", "flexer", "minimal")) {
            for (variant in 0..2) {
                for (isDark in listOf(false, true)) {
                    val p = OurneyGlanceTheme.skinPalette(skinId, variant, isDark)
                    assertTrue(
                        "onAccent contrast for $skinId/$variant (dark=$isDark) must be >= 4.5",
                        OurneyGlanceTheme.contrastRatio(p.onAccent, p.accent) >= 4.5,
                    )
                }
            }
        }
    }

    @Test
    fun `resolves 4-state card states per-widget pinned selections and fallback to auto on archive or delete`() {
        val store = WidgetSnapshotStore(tempFolder.newFolder("ourney_widgets_config"))
        val at1200Utc = Instant.parse("2026-11-24T12:00:00.000Z").toEpochMilli()

        // 1. Before first app sync (snapshot == null) -> Unsynced (never NoJourneys!)
        assertNull(store.readSnapshot(at1200Utc))
        assertEquals(
            JourneyWidgetCardState.Unsynced,
            WidgetSnapshot.resolveTodayCardState(null),
        )
        assertEquals(
            JourneyWidgetCardState.Unsynced,
            WidgetSnapshot.resolveStreakCardState(null),
        )
        assertEquals(
            SquadWidgetCardState.Unsynced,
            WidgetSnapshot.resolveSquadCardState(null),
        )

        // 2. Signed-out snapshot -> SignedOut
        val signedOutSnap = WidgetSnapshot.fromJson(
            """{"schemaVersion":1,"authState":"signedOut","journeys":[],"squads":[]}""",
        )
        assertEquals(
            JourneyWidgetCardState.SignedOut,
            WidgetSnapshot.resolveTodayCardState(signedOutSnap),
        )
        assertEquals(
            JourneyWidgetCardState.SignedOut,
            WidgetSnapshot.resolveStreakCardState(signedOutSnap),
        )
        assertEquals(
            SquadWidgetCardState.SignedOut,
            WidgetSnapshot.resolveSquadCardState(signedOutSnap),
        )

        // 3. Signed-in with 0 journeys -> NoJourneys / NoJourneysAtAll
        val emptyReadySnap = WidgetSnapshot.fromJson(
            """{"schemaVersion":1,"authState":"ready","journeys":[],"squads":[]}""",
        )
        assertEquals(
            JourneyWidgetCardState.NoJourneys,
            WidgetSnapshot.resolveTodayCardState(emptyReadySnap),
        )
        assertEquals(
            JourneyWidgetCardState.NoJourneys,
            WidgetSnapshot.resolveStreakCardState(emptyReadySnap),
        )
        assertEquals(
            SquadWidgetCardState.NoJourneysAtAll,
            WidgetSnapshot.resolveSquadCardState(emptyReadySnap),
        )

        // 4. Solo-only account on Squad widget (Rank 5) -> SoloOnlyAccount(soloCount = 2)
        val soloOnlySnap = WidgetSnapshot.fromJson(
            """
            {
              "schemaVersion": 1,
              "authState": "ready",
              "journeys": [
                {"id": "solo-1", "title": "Weight Loss", "kind": "solo", "isSensitive": true},
                {"id": "solo-2", "title": "Reading", "kind": "solo", "isSensitive": false}
              ],
              "squads": []
            }
            """.trimIndent(),
        )
        assertTrue(soloOnlySnap.journeys[0].isSensitive)
        assertFalse(soloOnlySnap.journeys[1].isSensitive)
        assertEquals(
            SquadWidgetCardState.SoloOnlyAccount(soloCount = 2),
            WidgetSnapshot.resolveSquadCardState(soloOnlySnap),
        )

        // 5. Ready snapshot with per-appWidgetId selection persistence and onDeleted cleanup
        store.writeSnapshotAtomically(sampleSnapshotJson)
        val readySnap = store.readSnapshot(at1200Utc)!!

        // Default selection is "auto" -> picks pending journey 6f8c9a10-0001
        assertEquals(WidgetSnapshot.AUTO_SELECTION_ID, store.getWidgetSelection(101))
        val autoToday = WidgetSnapshot.resolveTodayCardState(
            readySnap,
            selectedId = store.getWidgetSelection(101),
        ) as JourneyWidgetCardState.Ready
        assertEquals("6f8c9a10-0001", autoToday.journey.id)
        assertFalse(autoToday.isPinned)

        // Pin widget #101 to already-checked-in journey 6f8c9a10-0002 ->
        // shows 6f8c9a10-0002 with isPinned = true and pendingCount = 1 (hides cycle button!)
        store.setWidgetSelection(101, "6f8c9a10-0002")
        store.setWidgetSelection(102, "6f8c9a10-0001")
        assertEquals("6f8c9a10-0002", store.getWidgetSelection(101))
        assertEquals("6f8c9a10-0001", store.getWidgetSelection(102))

        val pinnedToday = WidgetSnapshot.resolveTodayCardState(
            readySnap,
            selectedId = store.getWidgetSelection(101),
        ) as JourneyWidgetCardState.Ready
        assertEquals("6f8c9a10-0002", pinnedToday.journey.id)
        assertTrue(pinnedToday.isPinned)
        assertEquals(1, pinnedToday.pendingCount)

        val pinnedStreak = WidgetSnapshot.resolveStreakCardState(
            readySnap,
            selectedId = store.getWidgetSelection(101),
        ) as JourneyWidgetCardState.Ready
        assertEquals("6f8c9a10-0002", pinnedStreak.journey.id)
        assertTrue(pinnedStreak.isPinned)

        // 6. Selection of a journey that no longer exists (archived/deleted) falls back to "auto"
        store.setWidgetSelection(103, "archived-journey-999")
        val fallbackToday = WidgetSnapshot.resolveTodayCardState(
            readySnap,
            selectedId = store.getWidgetSelection(103),
        ) as JourneyWidgetCardState.Ready
        assertEquals("6f8c9a10-0001", fallbackToday.journey.id)
        assertFalse("Fallback to auto must clear isPinned", fallbackToday.isPinned)

        val fallbackSquad = WidgetSnapshot.resolveSquadCardState(
            readySnap,
            selectedId = "deleted-squad-999",
        ) as SquadWidgetCardState.Ready
        assertEquals("6f8c9a10-0001", fallbackSquad.squad.journeyId)
        assertFalse(fallbackSquad.isPinned)

        // 7. Selecting "auto" or calling removeWidgetSelections (onDeleted) cleans up state.json
        store.setWidgetSelection(101, WidgetSnapshot.AUTO_SELECTION_ID)
        assertEquals(WidgetSnapshot.AUTO_SELECTION_ID, store.getWidgetSelection(101))

        store.removeWidgetSelections(intArrayOf(102, 103))
        assertEquals(WidgetSnapshot.AUTO_SELECTION_ID, store.getWidgetSelection(102))
        assertEquals(WidgetSnapshot.AUTO_SELECTION_ID, store.getWidgetSelection(103))
        assertTrue(store.readState().widgetSelections.isEmpty())

        // 8. Sign-out transition (P1-1): wiping store via clearAll() then writing the
        // signed-out snapshot resolves all 3 widget cards to SignedOut (not Unsynced)
        assertTrue(store.clearAll())
        store.writeSnapshotAtomically(
            """{"schemaVersion":1,"authState":"signedOut","locale":"vi","themeMode":"system","journeys":[],"squads":[]}""",
        )
        val postSignOutSnap = store.readSnapshot(at1200Utc)
        assertNotNull(postSignOutSnap)
        assertTrue(postSignOutSnap!!.isSignedOut)
        assertEquals(
            JourneyWidgetCardState.SignedOut,
            WidgetSnapshot.resolveTodayCardState(postSignOutSnap),
        )
        assertEquals(
            JourneyWidgetCardState.SignedOut,
            WidgetSnapshot.resolveStreakCardState(postSignOutSnap),
        )
        assertEquals(
            SquadWidgetCardState.SignedOut,
            WidgetSnapshot.resolveSquadCardState(postSignOutSnap),
        )
    }

    @Test
    fun `F-14 advances midnight evening streakAlert and reminder timestamps across multi-day rollover and DST`() {
        val store = WidgetSnapshotStore(tempFolder.newFolder("ourney_widgets_f14"))
        store.writeSnapshotAtomically(sampleSnapshotJson)

        // Day 1 -> Day 2 midnight (2026-11-24T17:05:00Z = 00:05 ICT on 2026-11-25)
        val day2MorningMs = Instant.parse("2026-11-24T17:05:00.000Z").toEpochMilli()
        val day2Snap = store.readSnapshot(day2MorningMs)!!

        val day2Ielts = day2Snap.journeys.first { it.id == "6f8c9a10-0001" }
        assertEquals("2026-11-25T11:00:00Z", day2Ielts.eveningCueAtUtc)
        assertEquals("2026-11-25T14:00:00Z", day2Ielts.streakAlertAtUtc)
        assertEquals("2026-11-25T17:00:00Z", day2Ielts.midnightRolloverUtc)
        assertEquals("2026-11-25T13:00:00Z", day2Ielts.reminderAtUtc)

        val day2Squad = day2Snap.squads.single()
        assertEquals("2026-11-25T17:00:00Z", day2Squad.midnightRolloverUtc)

        // nextRolloverEpochMs on Day 2 morning must find Day 2's 18:00 evening cue (never null!)
        val nextOnDay2Morning = day2Snap.nextRolloverEpochMs(day2MorningMs)
        assertNotNull("Rollover alarm must continue scheduling after Day 1 midnight", nextOnDay2Morning)
        assertEquals(Instant.parse("2026-11-25T11:00:00Z").toEpochMilli(), nextOnDay2Morning)

        // Day 2 -> Day 3 midnight (2026-11-25T17:05:00Z = 00:05 ICT on 2026-11-26, 2 days closed app)
        val day3MorningMs = Instant.parse("2026-11-25T17:05:00.000Z").toEpochMilli()
        val day3Snap = store.readSnapshot(day3MorningMs)!!
        val nextOnDay3Morning = day3Snap.nextRolloverEpochMs(day3MorningMs)
        assertNotNull("Rollover alarm must continue scheduling on Day 3+", nextOnDay3Morning)
        assertEquals(Instant.parse("2026-11-26T11:00:00Z").toEpochMilli(), nextOnDay3Morning)

        // DST Spring-Forward in America/New_York: 2026-03-08 is 23 hours long (EST -05:00 -> EDT -04:00).
        // Snapshot taken on 2026-03-07 (EST -05:00):
        // - 18:00 local = 2026-03-07T23:00:00Z
        // - 21:00 local = 2026-03-08T02:00:00Z
        // - 00:00 local (start of Mar 8) = 2026-03-08T05:00:00Z
        val dstSpringJson = """
            {
              "schemaVersion": 1,
              "authState": "ready",
              "locale": "en",
              "journeys": [
                {
                  "id": "ny-dst",
                  "title": "NY Spring Forward",
                  "timezone": "America/New_York",
                  "utcOffsetMinutes": -300,
                  "dayNumber": 1,
                  "totalDays": 30,
                  "currentStreak": 3,
                  "bestStreak": 3,
                  "checkedInToday": true,
                  "atRisk": false,
                  "eveningCueAtUtc": "2026-03-07T23:00:00Z",
                  "streakAlertAtUtc": "2026-03-08T02:00:00Z",
                  "midnightRolloverUtc": "2026-03-08T05:00:00Z",
                  "weekStrip": [
                    {"date": "2026-03-07", "day": 7, "label": "TD", "state": "done"}
                  ]
                }
              ],
              "squads": []
            }
        """.trimIndent()
        val dstSnap = WidgetSnapshot.fromJson(dstSpringJson)

        // At 2026-03-09T04:05:00Z (00:05 EDT on Mar 9 — only 23h 05m after Mar 8 midnight!):
        // Two midnights have crossed (Mar 8 00:00 EST and Mar 9 00:00 EDT), so daysPassed must be 2!
        val mar9MidnightPlus5m = Instant.parse("2026-03-09T04:05:00Z").toEpochMilli()
        val rolledDst = dstSnap.evaluateAt(mar9MidnightPlus5m)
        val nyRolled = rolledDst.journeys.single()
        assertEquals("23-hour DST spring-forward day must count as full calendar day", 3, nyRolled.dayNumber)
        assertEquals(0, nyRolled.currentStreak)
        // Next midnight is Mar 10 00:00 EDT (-04:00) = 2026-03-10T04:00:00Z
        assertEquals("2026-03-10T04:00:00Z", nyRolled.midnightRolloverUtc)
        // Next evening cue is Mar 9 18:00 EDT (-04:00) = 2026-03-09T22:00:00Z
        assertEquals("2026-03-09T22:00:00Z", nyRolled.eveningCueAtUtc)
        assertEquals(
            Instant.parse("2026-03-09T22:00:00Z").toEpochMilli(),
            rolledDst.nextRolloverEpochMs(mar9MidnightPlus5m),
        )
    }

    @Test
    fun `F-34 rollWeekStrip keeps English TD and single-letter weekdays instead of flipping to Vietnamese`() {
        val enSnapshotJson = """
            {
              "schemaVersion": 1,
              "authState": "ready",
              "locale": "en",
              "journeys": [
                {
                  "id": "en-journey",
                  "title": "Morning Run",
                  "timezone": "Asia/Ho_Chi_Minh",
                  "utcOffsetMinutes": 420,
                  "dayNumber": 7,
                  "totalDays": 30,
                  "currentStreak": 7,
                  "bestStreak": 7,
                  "checkedInToday": true,
                  "atRisk": false,
                  "midnightRolloverUtc": "2026-11-24T17:00:00.000Z",
                  "weekStrip": [
                    {"date": "2026-11-18", "day": 18, "label": "W", "state": "done"},
                    {"date": "2026-11-19", "day": 19, "label": "T", "state": "done"},
                    {"date": "2026-11-20", "day": 20, "label": "F", "state": "done"},
                    {"date": "2026-11-21", "day": 21, "label": "S", "state": "done"},
                    {"date": "2026-11-22", "day": 22, "label": "S", "state": "done"},
                    {"date": "2026-11-23", "day": 23, "label": "M", "state": "done"},
                    {"date": "2026-11-24", "day": 24, "label": "TD", "state": "done"}
                  ]
                }
              ],
              "squads": []
            }
        """.trimIndent()

        val postMidnightMs = Instant.parse("2026-11-24T17:05:00.000Z").toEpochMilli()
        val rolled = WidgetSnapshot.fromJson(enSnapshotJson).evaluateAt(postMidnightMs)
        val strip = rolled.journeys.single().weekStrip

        assertEquals(7, strip.size)
        // 2026-11-24 (Tuesday) was "TD" and must roll to English "T" (never Vietnamese "T3"!)
        assertEquals("2026-11-24", strip[5].date)
        assertEquals("T", strip[5].label)
        assertEquals("done", strip[5].state)
        // 2026-11-25 (Wednesday, new today) must stay English "TD" (never Vietnamese "HN"!)
        assertEquals("2026-11-25", strip[6].date)
        assertEquals("TD", strip[6].label)
        assertEquals("today", strip[6].state)
        assertEquals(listOf("T", "F", "S", "S", "M", "T", "TD"), strip.map { it.label })
    }

    @Test
    fun `applyWidgetSelectionToStores synchronizes state json and Glance preferences and generates unique per-widget URIs`() {
        val store = WidgetSnapshotStore(tempFolder.newFolder("ourney_widgets_dual_store"))
        val glancePrefs11 = mutablePreferencesOf(
            WidgetPrefsKeys.SNAPSHOT_SEQ to 1000L,
            WidgetPrefsKeys.CYCLE_INDEX to 2,
        )
        val glancePrefs12 = mutablePreferencesOf(
            WidgetPrefsKeys.SNAPSHOT_SEQ to 1000L,
        )

        // Guardrail 1: per-widget configure URI must be unique per appWidgetId so PendingIntents never collide
        val uri11 = WidgetActions.configureWidgetUriString(11)
        val uri12 = WidgetActions.configureWidgetUriString(12)
        assertEquals("ourney://widget-config/11", uri11)
        assertEquals("ourney://widget-config/12", uri12)
        assertNotEquals(uri11, uri12)

        // Guardrail 5: selecting a journey writes BOTH state.json and Glance preferences + resets CYCLE_INDEX
        assertTrue(
            WidgetActions.applyWidgetSelectionToStores(
                store = store,
                appWidgetId = 11,
                selectedId = "6f8c9a10-0002",
                glancePrefs = glancePrefs11,
                nowEpochMs = 2000L,
            ),
        )
        assertEquals("6f8c9a10-0002", store.getWidgetSelection(11))
        assertEquals("6f8c9a10-0002", glancePrefs11[WidgetPrefsKeys.SELECTED_ID])
        assertEquals(2000L, glancePrefs11[WidgetPrefsKeys.SNAPSHOT_SEQ])
        assertEquals(0, glancePrefs11[WidgetPrefsKeys.CYCLE_INDEX])

        // Widget #12 remains independent
        assertTrue(
            WidgetActions.applyWidgetSelectionToStores(
                store = store,
                appWidgetId = 12,
                selectedId = "6f8c9a10-0001",
                glancePrefs = glancePrefs12,
                nowEpochMs = 2005L,
            ),
        )
        assertEquals("6f8c9a10-0002", store.getWidgetSelection(11))
        assertEquals("6f8c9a10-0001", store.getWidgetSelection(12))
        assertEquals("6f8c9a10-0001", glancePrefs12[WidgetPrefsKeys.SELECTED_ID])

        // Switching widget #11 back to "auto" clears SELECTED_ID from both stores and increments SNAPSHOT_SEQ monotonically
        assertTrue(
            WidgetActions.applyWidgetSelectionToStores(
                store = store,
                appWidgetId = 11,
                selectedId = WidgetSnapshot.AUTO_SELECTION_ID,
                glancePrefs = glancePrefs11,
                nowEpochMs = 1500L, // even if clock is < prevSeq, seq advances monotonically
            ),
        )
        assertEquals(WidgetSnapshot.AUTO_SELECTION_ID, store.getWidgetSelection(11))
        assertNull(glancePrefs11[WidgetPrefsKeys.SELECTED_ID])
        assertEquals(2001L, glancePrefs11[WidgetPrefsKeys.SNAPSHOT_SEQ])
        assertEquals(0, glancePrefs11[WidgetPrefsKeys.CYCLE_INDEX])
    }

    @Test
    fun `Automatic Streak picks highest streak after check-in and Today cycles across all journeys when fewer than 2 are pending`() {
        val autoSnapshotJson = """
            {
              "schemaVersion": 1,
              "authState": "ready",
              "locale": "vi",
              "journeys": [
                {
                  "id": "j-unchecked-0",
                  "title": "Học từ vựng mới",
                  "kind": "solo",
                  "skinId": "squad",
                  "dayNumber": 1,
                  "totalDays": 30,
                  "currentStreak": 0,
                  "bestStreak": 0,
                  "checkedInToday": false,
                  "atRisk": false
                },
                {
                  "id": "j-checkedin-25",
                  "title": "Chạy bộ 25 ngày",
                  "kind": "solo",
                  "skinId": "flexer",
                  "dayNumber": 25,
                  "totalDays": 30,
                  "currentStreak": 25,
                  "bestStreak": 25,
                  "checkedInToday": true,
                  "atRisk": false
                }
              ],
              "squads": [
                {
                  "journeyId": "s-group-1",
                  "title": "Nhóm IELTS",
                  "skinId": "squad",
                  "isCouple": false,
                  "dayNumber": 10,
                  "doneCount": 2,
                  "memberCount": 4,
                  "meCheckedInToday": false,
                  "members": []
                },
                {
                  "journeyId": "s-couple-2",
                  "title": "Đôi mình",
                  "skinId": "couple",
                  "isCouple": true,
                  "dayNumber": 18,
                  "doneCount": 2,
                  "memberCount": 2,
                  "meCheckedInToday": true,
                  "members": []
                }
              ]
            }
        """.trimIndent()

        val snap = WidgetSnapshot.fromJson(autoSnapshotJson)
        assertNull(snap.defaultJourneyId)
        assertNull(snap.defaultSquadId)

        // 1. Streak widget in Automatic mode selects the 25-day streak even though it is checked in today!
        val autoStreak = WidgetSnapshot.resolveStreakCardState(snap) as JourneyWidgetCardState.Ready
        assertEquals("j-checkedin-25", autoStreak.journey.id)
        assertEquals(25, autoStreak.journey.currentStreak)

        // 2. Today widget in Automatic mode starts on the unchecked journey (1/2) AND keeps pendingCount = 2
        //    so the 1/2 › cycle button remains visible and cycles to the checked-in 25-day journey (2/2)!
        val today0 = WidgetSnapshot.resolveTodayCardState(
            snap,
            selectedId = WidgetSnapshot.AUTO_SELECTION_ID,
            cycleIndex = 0,
        ) as JourneyWidgetCardState.Ready
        assertEquals("j-unchecked-0", today0.journey.id)
        assertEquals(1, today0.pendingIndex)
        assertEquals(2, today0.pendingCount)

        val today1 = WidgetSnapshot.resolveTodayCardState(
            snap,
            selectedId = WidgetSnapshot.AUTO_SELECTION_ID,
            cycleIndex = 1,
        ) as JourneyWidgetCardState.Ready
        assertEquals("j-checkedin-25", today1.journey.id)
        assertEquals(2, today1.pendingIndex)
        assertEquals(2, today1.pendingCount)

        // 3. Even when ALL journeys are checked in today (0 pending), unpinned Today widget still cycles across all 2 journeys!
        val allDoneSnap = snap.copy(
            journeys = snap.journeys.map { it.copy(checkedInToday = true) },
        )
        val allDone0 = WidgetSnapshot.resolveTodayCardState(
            allDoneSnap,
            selectedId = WidgetSnapshot.AUTO_SELECTION_ID,
            cycleIndex = 0,
        ) as JourneyWidgetCardState.Ready
        val allDone1 = WidgetSnapshot.resolveTodayCardState(
            allDoneSnap,
            selectedId = WidgetSnapshot.AUTO_SELECTION_ID,
            cycleIndex = 1,
        ) as JourneyWidgetCardState.Ready
        assertEquals("j-unchecked-0", allDone0.journey.id)
        assertEquals(2, allDone0.pendingCount)
        assertEquals("j-checkedin-25", allDone1.journey.id)
        assertEquals(2, allDone1.pendingCount)

        // 4. Explicit defaultSquadId selects the second squad in Automatic mode
        val squadWithDefault = snap.copy(defaultSquadId = "s-couple-2")
        val resolvedSquad = WidgetSnapshot.resolveSquadCardState(squadWithDefault) as SquadWidgetCardState.Ready
        assertEquals("s-couple-2", resolvedSquad.squad.journeyId)
    }
}
