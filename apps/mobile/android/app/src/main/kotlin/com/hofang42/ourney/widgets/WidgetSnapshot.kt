package com.hofang42.ourney.widgets

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

/**
 * Frozen contract (§4.3) representation of `snapshot_v1.json`.
 *
 * Privacy-by-omission invariant: this model deliberately contains zero fields
 * for weight/metric values, metric units, health DNA, captions, or user PII.
 */
data class WidgetSnapshot(
    val schemaVersion: Int,
    val generatedAtUtc: String,
    val authState: String,
    val locale: String,
    val themeMode: String,
    val privacy: WidgetPrivacyConfig,
    val defaultJourneyId: String?,
    val totals: WidgetTotals,
    val journeys: List<WidgetJourneyItem>,
    val squads: List<WidgetSquadItem>,
    val liveWindow: WidgetLiveWindow?,
) {
    val isSignedOut: Boolean
        get() = authState == "signedOut" || authState == "unauthenticated"

    /**
     * Evaluates deterministic time-shifted state at [nowEpochMs] without waking
     * the Flutter engine:
     * - 18:00 (`eveningCueAtUtc`): evening nudge cue active
     * - 21:00 (`streakAlertAtUtc`): escalates unchecked active streak to `atRisk = true`
     * - 00:00 (`midnightRolloverUtc`): rolls over `checkedInToday -> false`, advances
     *   `dayNumber`, preserves or resets `currentStreak`, shifts `weekStrip`, and resets
     *   squad daily counts so a closed app never displays stale "Checked in today"
     *   on the next morning.
     */
    fun evaluateAt(nowEpochMs: Long): WidgetSnapshot {
        val evaluatedJourneys = journeys.map { it.evaluateAt(nowEpochMs) }
        val evaluatedSquads = squads.map { it.evaluateAt(nowEpochMs) }
        val evaluatedWindow = liveWindow?.takeIf { window ->
            val deadlineMs = parseIsoEpochMs(window.deadlineUtc)
            deadlineMs == null || nowEpochMs < deadlineMs
        }

        val completedCount = evaluatedJourneys.count { it.checkedInToday }
        val pendingCount = evaluatedJourneys.size - completedCount
        val atRiskCount = evaluatedJourneys.count { it.atRisk && !it.checkedInToday }
        val bestActiveStreak = evaluatedJourneys.maxOfOrNull { it.currentStreak } ?: 0

        val updatedTotals = WidgetTotals(
            activeCount = evaluatedJourneys.size,
            completedTodayCount = completedCount,
            pendingTodayCount = pendingCount,
            atRiskCount = atRiskCount,
            bestActiveStreak = bestActiveStreak,
        )

        return copy(
            totals = updatedTotals,
            journeys = evaluatedJourneys,
            squads = evaluatedSquads,
            liveWindow = evaluatedWindow,
        )
    }

    /**
     * Selects the primary journey to display in `OurneyTodayWidget`, supporting
     * interactive cycling across pending journeys via [state.selectedTodayIndex].
     */
    fun selectTodayJourney(state: WidgetMutableState): WidgetJourneyItem? {
        if (journeys.isEmpty()) return null
        val pending = journeys.filter { !it.checkedInToday }
        if (pending.size >= 2) {
            val idx = state.selectedTodayIndex.mod(pending.size)
            return pending[idx]
        }
        if (pending.size == 1) {
            return pending.first()
        }
        if (!defaultJourneyId.isNullOrBlank()) {
            journeys.firstOrNull { it.id == defaultJourneyId }?.let { return it }
        }
        return journeys.first()
    }

    /**
     * Selects the journey for `OurneyStreakWidget` (prefers `defaultJourneyId`,
     * then highest active streak or first journey).
     */
    fun selectStreakJourney(): WidgetJourneyItem? {
        if (journeys.isEmpty()) return null
        if (!defaultJourneyId.isNullOrBlank()) {
            journeys.firstOrNull { it.id == defaultJourneyId }?.let { return it }
        }
        return journeys.maxByOrNull { it.currentStreak } ?: journeys.first()
    }

    /**
     * Selects the primary squad/couple journey for `OurneySquadWidget`.
     */
    fun selectSquad(): WidgetSquadItem? {
        if (squads.isEmpty()) return null
        if (!defaultJourneyId.isNullOrBlank()) {
            squads.firstOrNull { it.journeyId == defaultJourneyId }?.let { return it }
        }
        return squads.first()
    }

    /**
     * Collects all relative thumbnail paths (`thumbs/<id>.jpg`) referenced by
     * this snapshot so orphan files can be pruned safely.
     */
    fun referencedThumbPaths(): Set<String> {
        val paths = mutableSetOf<String>()
        for (j in journeys) {
            j.heroThumbFile?.takeIf { it.isNotBlank() }?.let { paths.add(it) }
        }
        for (s in squads) {
            for (m in s.members) {
                m.avatarFile?.takeIf { it.isNotBlank() }?.let { paths.add(it) }
                m.todayThumbFile?.takeIf { it.isNotBlank() }?.let { paths.add(it) }
            }
        }
        return paths
    }

    /**
     * Finds the earliest upcoming state transition timestamp (evening cue,
     * 21:00 streak alert, live window start, or midnight rollover) after [nowEpochMs].
     */
    fun nextRolloverEpochMs(nowEpochMs: Long): Long? {
        val candidates = mutableListOf<Long>()
        for (j in journeys) {
            parseIsoEpochMs(j.eveningCueAtUtc)?.takeIf { it > nowEpochMs }?.let(candidates::add)
            parseIsoEpochMs(j.streakAlertAtUtc)?.takeIf { it > nowEpochMs }?.let(candidates::add)
            parseIsoEpochMs(j.midnightRolloverUtc)?.takeIf { it > nowEpochMs }?.let(candidates::add)
        }
        for (s in squads) {
            parseIsoEpochMs(s.midnightRolloverUtc)?.takeIf { it > nowEpochMs }?.let(candidates::add)
        }
        liveWindow?.let { w ->
            parseIsoEpochMs(w.windowStartUtc)?.takeIf { it > nowEpochMs }?.let(candidates::add)
            parseIsoEpochMs(w.deadlineUtc)?.takeIf { it > nowEpochMs }?.let(candidates::add)
        }
        return candidates.minOrNull()
    }

    companion object {
        fun parseIsoEpochMs(iso: String?): Long? {
            if (iso.isNullOrBlank()) return null
            return try {
                Instant.parse(iso).toEpochMilli()
            } catch (_: Exception) {
                null
            }
        }

        fun fromJson(jsonString: String): WidgetSnapshot {
            val root = JSONObject(jsonString)
            val schemaVersion = root.optInt("schemaVersion", 1)
            val generatedAtUtc = root.optString("generatedAtUtc", "")
            val authState = root.optString("authState", "ready")
            val locale = root.optString("locale", "vi").ifBlank { "vi" }
            val themeMode = root.optString("themeMode", "system").ifBlank { "system" }
            val privacyObj = root.optJSONObject("privacy") ?: JSONObject()
            val privacy = WidgetPrivacyConfig(
                photoMode = privacyObj.optString("photoMode", "smart").ifBlank { "smart" },
                redactLockScreenTitles = privacyObj.optBoolean("redactLockScreenTitles", false),
                liveActivityEnabled = privacyObj.optBoolean("liveActivityEnabled", true),
            )
            val defaultJourneyId = root.optString("defaultJourneyId", "").takeIf { it.isNotBlank() }

            val totalsObj = root.optJSONObject("totals") ?: JSONObject()
            val journeysArr = root.optJSONArray("journeys") ?: JSONArray()
            val journeys = buildList {
                for (i in 0 until journeysArr.length()) {
                    journeysArr.optJSONObject(i)?.let { add(WidgetJourneyItem.fromJson(it)) }
                }
            }

            val squadsArr = root.optJSONArray("squads") ?: JSONArray()
            val squads = buildList {
                for (i in 0 until squadsArr.length()) {
                    squadsArr.optJSONObject(i)?.let { add(WidgetSquadItem.fromJson(it)) }
                }
            }

            val totals = WidgetTotals(
                activeCount = totalsObj.optInt("activeCount", journeys.size),
                completedTodayCount = totalsObj.optInt(
                    "completedTodayCount",
                    journeys.count { it.checkedInToday },
                ),
                pendingTodayCount = totalsObj.optInt(
                    "pendingTodayCount",
                    journeys.count { !it.checkedInToday },
                ),
                atRiskCount = totalsObj.optInt(
                    "atRiskCount",
                    journeys.count { it.atRisk && !it.checkedInToday },
                ),
                bestActiveStreak = totalsObj.optInt(
                    "bestActiveStreak",
                    journeys.maxOfOrNull { it.currentStreak } ?: 0,
                ),
            )

            val liveWindow = root.optJSONObject("liveWindow")?.let { WidgetLiveWindow.fromJson(it) }

            return WidgetSnapshot(
                schemaVersion = schemaVersion,
                generatedAtUtc = generatedAtUtc,
                authState = authState,
                locale = locale,
                themeMode = themeMode,
                privacy = privacy,
                defaultJourneyId = defaultJourneyId,
                totals = totals,
                journeys = journeys,
                squads = squads,
                liveWindow = liveWindow,
            )
        }
    }
}

data class WidgetPrivacyConfig(
    val photoMode: String = "smart",
    val redactLockScreenTitles: Boolean = false,
    val liveActivityEnabled: Boolean = true,
)

data class WidgetTotals(
    val activeCount: Int = 0,
    val completedTodayCount: Int = 0,
    val pendingTodayCount: Int = 0,
    val atRiskCount: Int = 0,
    val bestActiveStreak: Int = 0,
)

data class WidgetJourneyItem(
    val id: String,
    val title: String,
    val kind: String,
    val skinId: String,
    val colorVariant: Int,
    val typeIcon: String,
    val timezone: String,
    val utcOffsetMinutes: Int,
    val pinned: Boolean,
    val dayNumber: Int,
    val totalDays: Int,
    val currentStreak: Int,
    val bestStreak: Int,
    val checkedInToday: Boolean,
    val atRisk: Boolean,
    val eveningCueAtUtc: String?,
    val streakAlertAtUtc: String?,
    val midnightRolloverUtc: String?,
    val reminderAtUtc: String?,
    val heroThumbFile: String?,
    val heroThumbBlurred: Boolean,
    val weekStrip: List<WidgetWeekDay>,
) {
    fun isEveningCueActive(nowEpochMs: Long): Boolean {
        if (checkedInToday) return false
        val cueMs = WidgetSnapshot.parseIsoEpochMs(eveningCueAtUtc) ?: return false
        return nowEpochMs >= cueMs
    }

    fun evaluateAt(nowEpochMs: Long): WidgetJourneyItem {
        val midnightMs = WidgetSnapshot.parseIsoEpochMs(midnightRolloverUtc)
        if (midnightMs != null && nowEpochMs >= midnightMs) {
            val daysPassed = ((nowEpochMs - midnightMs) / 86_400_000L).toInt() + 1
            val survivedFirstRollover = daysPassed == 1 && checkedInToday
            val newStreak = if (survivedFirstRollover) currentStreak else 0
            val newAtRisk = newStreak > 0
            val rawNewDay = dayNumber + daysPassed
            val newDayNumber = if (totalDays > 0) minOf(rawNewDay, totalDays) else rawNewDay
            val rolledStrip = rollWeekStrip(weekStrip, daysPassed, checkedInToday)
            return copy(
                dayNumber = newDayNumber,
                currentStreak = newStreak,
                checkedInToday = false,
                atRisk = newAtRisk,
                weekStrip = rolledStrip,
            )
        }

        val streakAlertMs = WidgetSnapshot.parseIsoEpochMs(streakAlertAtUtc)
        val escalatedAtRisk =
            if (!checkedInToday && currentStreak > 0 && streakAlertMs != null && nowEpochMs >= streakAlertMs) {
                true
            } else {
                atRisk
            }
        return if (escalatedAtRisk != atRisk) copy(atRisk = escalatedAtRisk) else this
    }

    companion object {
        private fun rollWeekStrip(
            strip: List<WidgetWeekDay>,
            daysPassed: Int,
            wasCheckedInBeforeMidnight: Boolean,
        ): List<WidgetWeekDay> {
            if (strip.isEmpty() || daysPassed <= 0) return strip
            val finalized = strip.mapIndexed { index, item ->
                if (index == strip.lastIndex && (item.state == "today" || item.state == "done")) {
                    item.copy(state = if (wasCheckedInBeforeMidnight) "done" else "missed")
                } else {
                    item
                }
            }
            if (daysPassed >= strip.size) {
                return finalized.mapIndexed { idx, item ->
                    item.copy(state = if (idx == finalized.lastIndex) "today" else "missed")
                }
            }
            val lastDate = try {
                LocalDate.parse(strip.last().date, DateTimeFormatter.ISO_LOCAL_DATE)
            } catch (_: Exception) {
                null
            }
            val kept = finalized.drop(daysPassed).toMutableList()
            for (step in 1..daysPassed) {
                val nextDate = lastDate?.plusDays(step.toLong())
                val isTodaySlot = step == daysPassed
                kept.add(
                    WidgetWeekDay(
                        date = nextDate?.format(DateTimeFormatter.ISO_LOCAL_DATE) ?: "",
                        day = nextDate?.dayOfMonth ?: ((strip.last().day + step - 1) % 31 + 1),
                        label = strip.last().label,
                        state = if (isTodaySlot) "today" else "missed",
                    ),
                )
            }
            return kept
        }

        fun fromJson(obj: JSONObject): WidgetJourneyItem {
            val stripArr = obj.optJSONArray("weekStrip") ?: JSONArray()
            val strip = buildList {
                for (i in 0 until stripArr.length()) {
                    stripArr.optJSONObject(i)?.let { add(WidgetWeekDay.fromJson(it)) }
                }
            }
            return WidgetJourneyItem(
                id = obj.optString("id", ""),
                title = obj.optString("title", ""),
                kind = obj.optString("kind", "solo"),
                skinId = obj.optString("skinId", "minimal").ifBlank { "minimal" },
                colorVariant = obj.optInt("colorVariant", 0),
                typeIcon = obj.optString("typeIcon", "type-custom").ifBlank { "type-custom" },
                timezone = obj.optString("timezone", "UTC"),
                utcOffsetMinutes = obj.optInt("utcOffsetMinutes", 0),
                pinned = obj.optBoolean("pinned", false),
                dayNumber = obj.optInt("dayNumber", 1),
                totalDays = obj.optInt("totalDays", 30),
                currentStreak = obj.optInt("currentStreak", 0),
                bestStreak = obj.optInt("bestStreak", 0),
                checkedInToday = obj.optBoolean("checkedInToday", false),
                atRisk = obj.optBoolean("atRisk", false),
                eveningCueAtUtc = obj.optString("eveningCueAtUtc", "").takeIf { it.isNotBlank() },
                streakAlertAtUtc = obj.optString("streakAlertAtUtc", "").takeIf { it.isNotBlank() },
                midnightRolloverUtc = obj.optString("midnightRolloverUtc", "").takeIf { it.isNotBlank() },
                reminderAtUtc = obj.optString("reminderAtUtc", "").takeIf { it.isNotBlank() },
                heroThumbFile = obj.optString("heroThumbFile", "").takeIf { it.isNotBlank() },
                heroThumbBlurred = obj.optBoolean("heroThumbBlurred", false),
                weekStrip = strip,
            )
        }
    }
}

data class WidgetWeekDay(
    val date: String,
    val day: Int,
    val label: String,
    val state: String,
) {
    companion object {
        fun fromJson(obj: JSONObject): WidgetWeekDay = WidgetWeekDay(
            date = obj.optString("date", ""),
            day = obj.optInt("day", 1),
            label = obj.optString("label", ""),
            state = obj.optString("state", "future"),
        )
    }
}

data class WidgetSquadItem(
    val journeyId: String,
    val title: String,
    val skinId: String,
    val colorVariant: Int,
    val typeIcon: String,
    val isCouple: Boolean,
    val dayNumber: Int,
    val totalDays: Int,
    val doneCount: Int,
    val memberCount: Int,
    val meCheckedInToday: Boolean,
    val midnightRolloverUtc: String?,
    val members: List<WidgetSquadMember>,
) {
    fun evaluateAt(nowEpochMs: Long): WidgetSquadItem {
        val midnightMs = WidgetSnapshot.parseIsoEpochMs(midnightRolloverUtc)
        if (midnightMs != null && nowEpochMs >= midnightMs) {
            val daysPassed = ((nowEpochMs - midnightMs) / 86_400_000L).toInt() + 1
            val rawNewDay = dayNumber + daysPassed
            val newDayNumber = if (totalDays > 0) minOf(rawNewDay, totalDays) else rawNewDay
            return copy(
                dayNumber = newDayNumber,
                doneCount = 0,
                meCheckedInToday = false,
                members = members.map { member ->
                    member.copy(
                        checkedInToday = false,
                        streak = if (daysPassed == 1 && member.checkedInToday) member.streak else 0,
                        todayThumbFile = null,
                    )
                },
            )
        }
        return this
    }

    companion object {
        fun fromJson(obj: JSONObject): WidgetSquadItem {
            val membersArr = obj.optJSONArray("members") ?: JSONArray()
            val members = buildList {
                for (i in 0 until membersArr.length()) {
                    membersArr.optJSONObject(i)?.let { add(WidgetSquadMember.fromJson(it)) }
                }
            }
            return WidgetSquadItem(
                journeyId = obj.optString("journeyId", ""),
                title = obj.optString("title", ""),
                skinId = obj.optString("skinId", "squad").ifBlank { "squad" },
                colorVariant = obj.optInt("colorVariant", 0),
                typeIcon = obj.optString("typeIcon", "type-study").ifBlank { "type-study" },
                isCouple = obj.optBoolean("isCouple", false),
                dayNumber = obj.optInt("dayNumber", 1),
                totalDays = obj.optInt("totalDays", 30),
                doneCount = obj.optInt("doneCount", 0),
                memberCount = obj.optInt("memberCount", members.size),
                meCheckedInToday = obj.optBoolean("meCheckedInToday", false),
                midnightRolloverUtc = obj.optString("midnightRolloverUtc", "").takeIf { it.isNotBlank() },
                members = members,
            )
        }
    }
}

data class WidgetSquadMember(
    val displayName: String,
    val initial: String,
    val avatarColorIndex: Int,
    val isMe: Boolean,
    val checkedInToday: Boolean,
    val streak: Int,
    val avatarFile: String?,
    val todayThumbFile: String?,
    val todayThumbBlurred: Boolean,
) {
    companion object {
        fun fromJson(obj: JSONObject): WidgetSquadMember {
            val name = obj.optString("displayName", "")
            val fallbackInitial = name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "?"
            return WidgetSquadMember(
                displayName = name,
                initial = obj.optString("initial", fallbackInitial).ifBlank { fallbackInitial },
                avatarColorIndex = obj.optInt("avatarColorIndex", 0),
                isMe = obj.optBoolean("isMe", false),
                checkedInToday = obj.optBoolean("checkedInToday", false),
                streak = obj.optInt("streak", 0),
                avatarFile = obj.optString("avatarFile", "").takeIf { it.isNotBlank() },
                todayThumbFile = obj.optString("todayThumbFile", "").takeIf { it.isNotBlank() },
                todayThumbBlurred = obj.optBoolean("todayThumbBlurred", false),
            )
        }
    }
}

data class WidgetLiveWindow(
    val windowKey: String,
    val journeyId: String,
    val journeyTitle: String,
    val skinId: String,
    val colorVariant: Int,
    val typeIcon: String,
    val currentStreak: Int,
    val atRisk: Boolean,
    val pendingCount: Int,
    val completedCount: Int,
    val totalActiveCount: Int,
    val windowStartUtc: String,
    val deadlineUtc: String,
    val celebrateAndDismiss: Boolean = false,
) {
    fun isActiveAt(nowEpochMs: Long, state: WidgetMutableState): Boolean {
        if (state.dismissedWindowKey == windowKey) return false
        val startMs = WidgetSnapshot.parseIsoEpochMs(windowStartUtc)
        val deadlineMs = WidgetSnapshot.parseIsoEpochMs(deadlineUtc) ?: return false
        if (nowEpochMs >= deadlineMs) return false
        return startMs == null || nowEpochMs >= startMs
    }

    companion object {
        fun fromJson(obj: JSONObject): WidgetLiveWindow? {
            val journeyId = obj.optString("journeyId", "")
            val deadlineUtc = obj.optString("deadlineUtc", "")
            if (journeyId.isBlank() && !obj.optBoolean("celebrateAndDismiss", false)) return null
            return WidgetLiveWindow(
                windowKey = obj.optString("windowKey", ""),
                journeyId = journeyId,
                journeyTitle = obj.optString("journeyTitle", ""),
                skinId = obj.optString("skinId", "squad").ifBlank { "squad" },
                colorVariant = obj.optInt("colorVariant", 0),
                typeIcon = obj.optString("typeIcon", "type-study").ifBlank { "type-study" },
                currentStreak = obj.optInt("currentStreak", 0),
                atRisk = obj.optBoolean("atRisk", false),
                pendingCount = obj.optInt("pendingCount", 0),
                completedCount = obj.optInt("completedCount", 0),
                totalActiveCount = obj.optInt("totalActiveCount", 1),
                windowStartUtc = obj.optString("windowStartUtc", ""),
                deadlineUtc = deadlineUtc,
                celebrateAndDismiss = obj.optBoolean("celebrateAndDismiss", false),
            )
        }

        fun fromMap(map: Map<*, *>): WidgetLiveWindow {
            val json = JSONObject()
            for ((k, v) in map) {
                if (k is String && v != null) {
                    json.put(k, v)
                }
            }
            return fromJson(json) ?: WidgetLiveWindow(
                windowKey = (map["windowKey"] as? String).orEmpty(),
                journeyId = (map["journeyId"] as? String).orEmpty(),
                journeyTitle = (map["journeyTitle"] as? String).orEmpty(),
                skinId = (map["skinId"] as? String) ?: "squad",
                colorVariant = (map["colorVariant"] as? Number)?.toInt() ?: 0,
                typeIcon = (map["typeIcon"] as? String) ?: "type-study",
                currentStreak = (map["currentStreak"] as? Number)?.toInt() ?: 0,
                atRisk = (map["atRisk"] as? Boolean) ?: false,
                pendingCount = (map["pendingCount"] as? Number)?.toInt() ?: 0,
                completedCount = (map["completedCount"] as? Number)?.toInt() ?: 0,
                totalActiveCount = (map["totalActiveCount"] as? Number)?.toInt() ?: 1,
                windowStartUtc = (map["windowStartUtc"] as? String).orEmpty(),
                deadlineUtc = (map["deadlineUtc"] as? String).orEmpty(),
                celebrateAndDismiss = (map["celebrateAndDismiss"] as? Boolean) ?: false,
            )
        }
    }
}

/**
 * Mutable interactive widget state stored in `state.json` so Glance
 * `ActionCallback`s and `CheckInWindowReceiver` never mutate `snapshot_v1.json`.
 */
data class WidgetMutableState(
    val selectedTodayIndex: Int = 0,
    val dismissedWindowKey: String? = null,
    val dismissedWindowDate: String? = null,
) {
    fun toJsonString(): String {
        val obj = JSONObject()
        obj.put("selectedTodayIndex", selectedTodayIndex)
        if (!dismissedWindowKey.isNullOrBlank()) {
            obj.put("dismissedWindowKey", dismissedWindowKey)
        }
        if (!dismissedWindowDate.isNullOrBlank()) {
            obj.put("dismissedWindowDate", dismissedWindowDate)
        }
        return obj.toString()
    }

    fun toMap(): Map<String, Any?> = buildMap {
        put("selectedTodayIndex", selectedTodayIndex)
        if (!dismissedWindowKey.isNullOrBlank()) {
            put("dismissedWindowKey", dismissedWindowKey)
        }
        if (!dismissedWindowDate.isNullOrBlank()) {
            put("dismissedWindowDate", dismissedWindowDate)
        }
    }

    companion object {
        fun todayUtcDateString(nowEpochMs: Long = System.currentTimeMillis()): String =
            Instant.ofEpochMilli(nowEpochMs).atOffset(ZoneOffset.UTC).toLocalDate().toString()

        fun fromJson(jsonString: String): WidgetMutableState {
            val obj = JSONObject(jsonString)
            return WidgetMutableState(
                selectedTodayIndex = obj.optInt("selectedTodayIndex", 0).coerceAtLeast(0),
                dismissedWindowKey = obj.optString("dismissedWindowKey", "").takeIf { it.isNotBlank() },
                dismissedWindowDate = obj.optString("dismissedWindowDate", "").takeIf { it.isNotBlank() },
            )
        }
    }
}

data class ThumbSpec(
    val id: String,
    val sourcePath: String,
    val maxSide: Int,
    val blur: Boolean,
) {
    companion object {
        fun fromMap(map: Map<*, *>): ThumbSpec? {
            val id = (map["id"] as? String)?.trim()?.takeIf { it.isNotEmpty() } ?: return null
            val sourcePath = (map["sourcePath"] as? String)?.trim()?.takeIf { it.isNotEmpty() } ?: return null
            val maxSide = ((map["maxSide"] as? Number)?.toInt() ?: 320).coerceIn(64, 512)
            val blur = (map["blur"] as? Boolean) ?: false
            return ThumbSpec(id = id, sourcePath = sourcePath, maxSide = maxSide, blur = blur)
        }
    }
}
