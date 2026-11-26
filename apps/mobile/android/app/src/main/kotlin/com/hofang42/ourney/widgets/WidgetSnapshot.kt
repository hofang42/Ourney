package com.hofang42.ourney.widgets

import org.json.JSONArray
import org.json.JSONObject
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

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
        val evaluatedJourneys = journeys.map { it.evaluateAt(nowEpochMs, locale) }
        val evaluatedSquads = squads.map { squad ->
            val matchingJourney = journeys.firstOrNull { it.id == squad.journeyId }
            squad.evaluateAt(
                nowEpochMs = nowEpochMs,
                timezone = matchingJourney?.timezone,
                utcOffsetMinutes = matchingJourney?.utcOffsetMinutes ?: 0,
            )
        }
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
     * per-widget pinned [selectedId] (falling back to `"auto"` when the pinned
     * journey ends, archives, or is deleted) and interactive cycling across
     * pending journeys via [cycleIndex].
     */
    fun selectTodayJourney(
        selectedId: String? = AUTO_SELECTION_ID,
        cycleIndex: Int = 0,
    ): WidgetJourneyItem? {
        if (journeys.isEmpty()) return null
        val normalizedId = selectedId?.trim()?.takeIf { it.isNotEmpty() } ?: AUTO_SELECTION_ID
        if (normalizedId != AUTO_SELECTION_ID) {
            journeys.firstOrNull { it.id == normalizedId }?.let { return it }
        }
        val pending = journeys.filter { !it.checkedInToday }
        if (pending.size >= 2) {
            val idx = cycleIndex.coerceAtLeast(0).mod(pending.size)
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

    fun selectTodayJourney(state: WidgetMutableState): WidgetJourneyItem? =
        selectTodayJourney(
            selectedId = AUTO_SELECTION_ID,
            cycleIndex = state.selectedTodayIndex,
        )

    /**
     * True when [selectedId] pins an active journey currently present in [journeys].
     */
    fun isPinnedJourneyActive(selectedId: String?): Boolean {
        val normalizedId = selectedId?.trim()?.takeIf { it.isNotEmpty() } ?: return false
        if (normalizedId == AUTO_SELECTION_ID) return false
        return journeys.any { it.id == normalizedId }
    }

    /**
     * True when [selectedId] pins an active squad currently present in [squads].
     */
    fun isPinnedSquadActive(selectedId: String?): Boolean {
        val normalizedId = selectedId?.trim()?.takeIf { it.isNotEmpty() } ?: return false
        if (normalizedId == AUTO_SELECTION_ID) return false
        return squads.any { it.journeyId == normalizedId }
    }

    /**
     * Selects the journey for `OurneyStreakWidget` (prefers per-widget pinned
     * [selectedId], falling back to `defaultJourneyId`, then highest active
     * streak or first journey).
     */
    fun selectStreakJourney(selectedId: String? = AUTO_SELECTION_ID): WidgetJourneyItem? {
        if (journeys.isEmpty()) return null
        val normalizedId = selectedId?.trim()?.takeIf { it.isNotEmpty() } ?: AUTO_SELECTION_ID
        if (normalizedId != AUTO_SELECTION_ID) {
            journeys.firstOrNull { it.id == normalizedId }?.let { return it }
        }
        if (!defaultJourneyId.isNullOrBlank()) {
            journeys.firstOrNull { it.id == defaultJourneyId }?.let { return it }
        }
        return journeys.maxByOrNull { it.currentStreak } ?: journeys.first()
    }

    /**
     * Selects the primary squad/couple journey for `OurneySquadWidget` (prefers
     * per-widget pinned [selectedId], falling back to `defaultJourneyId` or first squad).
     */
    fun selectSquad(selectedId: String? = AUTO_SELECTION_ID): WidgetSquadItem? {
        if (squads.isEmpty()) return null
        val normalizedId = selectedId?.trim()?.takeIf { it.isNotEmpty() } ?: AUTO_SELECTION_ID
        if (normalizedId != AUTO_SELECTION_ID) {
            squads.firstOrNull { it.journeyId == normalizedId }?.let { return it }
        }
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
        const val AUTO_SELECTION_ID = "auto"

        fun resolveTodayCardState(
            snapshot: WidgetSnapshot?,
            selectedId: String? = AUTO_SELECTION_ID,
            cycleIndex: Int = 0,
        ): JourneyWidgetCardState {
            if (snapshot == null) return JourneyWidgetCardState.Unsynced
            if (snapshot.isSignedOut) return JourneyWidgetCardState.SignedOut
            val journey = snapshot.selectTodayJourney(selectedId, cycleIndex)
                ?: return JourneyWidgetCardState.NoJourneys
            val isPinned = snapshot.isPinnedJourneyActive(selectedId)
            val pending = snapshot.journeys.filter { !it.checkedInToday }
            val pendingIndex = if (!isPinned && pending.size >= 2) {
                (pending.indexOfFirst { it.id == journey.id }.takeIf { it >= 0 } ?: 0) + 1
            } else {
                1
            }
            val pendingCount = if (isPinned) 1 else pending.size
            return JourneyWidgetCardState.Ready(
                journey = journey,
                isPinned = isPinned,
                pendingIndex = pendingIndex,
                pendingCount = pendingCount,
            )
        }

        fun resolveStreakCardState(
            snapshot: WidgetSnapshot?,
            selectedId: String? = AUTO_SELECTION_ID,
        ): JourneyWidgetCardState {
            if (snapshot == null) return JourneyWidgetCardState.Unsynced
            if (snapshot.isSignedOut) return JourneyWidgetCardState.SignedOut
            val journey = snapshot.selectStreakJourney(selectedId)
                ?: return JourneyWidgetCardState.NoJourneys
            return JourneyWidgetCardState.Ready(
                journey = journey,
                isPinned = snapshot.isPinnedJourneyActive(selectedId),
                pendingIndex = 1,
                pendingCount = 1,
            )
        }

        fun resolveSquadCardState(
            snapshot: WidgetSnapshot?,
            selectedId: String? = AUTO_SELECTION_ID,
        ): SquadWidgetCardState {
            if (snapshot == null) return SquadWidgetCardState.Unsynced
            if (snapshot.isSignedOut) return SquadWidgetCardState.SignedOut
            val squad = snapshot.selectSquad(selectedId)
            if (squad == null) {
                return if (snapshot.journeys.isNotEmpty()) {
                    SquadWidgetCardState.SoloOnlyAccount(soloCount = snapshot.journeys.size)
                } else {
                    SquadWidgetCardState.NoJourneysAtAll
                }
            }
            return SquadWidgetCardState.Ready(
                squad = squad,
                isPinned = snapshot.isPinnedSquadActive(selectedId),
            )
        }

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
            val schemaVersion = root.optIntCompat("schemaVersion", 1)
            val generatedAtUtc = root.optCleanString("generatedAtUtc", "")
            val authState = root.optCleanString("authState", "ready")
            val locale = root.optCleanString("locale", "vi")
            val themeMode = root.optCleanString("themeMode", "system")
            val privacyObj = root.optObjectOrNull("privacy")
            val redactLockScreenTitles = when {
                privacyObj == null -> false
                privacyObj.has("redactLockScreenTitles") && !privacyObj.isNull("redactLockScreenTitles") ->
                    privacyObj.optBoolean("redactLockScreenTitles", false)
                privacyObj.has("redactTitleOnLockScreen") && !privacyObj.isNull("redactTitleOnLockScreen") ->
                    privacyObj.optBoolean("redactTitleOnLockScreen", false)
                else -> false
            }
            val privacy = WidgetPrivacyConfig(
                photoMode = privacyObj?.optCleanString("photoMode", "smart") ?: "smart",
                redactLockScreenTitles = redactLockScreenTitles,
                liveActivityEnabled = privacyObj?.optBooleanCompat("liveActivityEnabled", true) ?: true,
            )
            val defaultJourneyId = root.optNullableString("defaultJourneyId")

            val totalsObj = root.optObjectOrNull("totals")
            val journeysArr = root.optArrayOrNull("journeys") ?: JSONArray()
            val journeys = buildList {
                for (i in 0 until journeysArr.length()) {
                    journeysArr.optJSONObject(i)?.let { add(WidgetJourneyItem.fromJson(it)) }
                }
            }

            val squadsArr = root.optArrayOrNull("squads") ?: JSONArray()
            val squads = buildList {
                for (i in 0 until squadsArr.length()) {
                    squadsArr.optJSONObject(i)?.let { add(WidgetSquadItem.fromJson(it)) }
                }
            }

            val totals = WidgetTotals(
                activeCount = totalsObj?.optIntCompat("activeCount", journeys.size) ?: journeys.size,
                completedTodayCount = totalsObj?.optIntCompat(
                    "completedTodayCount",
                    journeys.count { it.checkedInToday },
                ) ?: journeys.count { it.checkedInToday },
                pendingTodayCount = totalsObj?.optIntCompat(
                    "pendingTodayCount",
                    journeys.count { !it.checkedInToday },
                ) ?: journeys.count { !it.checkedInToday },
                atRiskCount = totalsObj?.optIntCompat(
                    "atRiskCount",
                    journeys.count { it.atRisk && !it.checkedInToday },
                ) ?: journeys.count { it.atRisk && !it.checkedInToday },
                bestActiveStreak = totalsObj?.optIntCompat(
                    "bestActiveStreak",
                    journeys.maxOfOrNull { it.currentStreak } ?: 0,
                ) ?: (journeys.maxOfOrNull { it.currentStreak } ?: 0),
            )

            val liveWindow = root.optObjectOrNull("liveWindow")?.let { WidgetLiveWindow.fromJson(it) }

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
    val totalDays: Int?,
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
    val isSensitive: Boolean = false,
) {
    val isOpenEnded: Boolean
        get() = totalDays == null || totalDays <= 0

    fun isEveningCueActive(nowEpochMs: Long): Boolean {
        if (checkedInToday) return false
        val cueMs = WidgetSnapshot.parseIsoEpochMs(eveningCueAtUtc) ?: return false
        val midnightMs = WidgetSnapshot.parseIsoEpochMs(midnightRolloverUtc)
        if (midnightMs != null && nowEpochMs >= midnightMs) {
            val zone = resolveZoneId(timezone, utcOffsetMinutes)
            val daysPassed = extraDaysPassed(midnightMs, nowEpochMs, zone)
            val shiftedCueUtc = shiftIsoUtcByDays(eveningCueAtUtc, daysPassed, zone)
            val shiftedCueMs = WidgetSnapshot.parseIsoEpochMs(shiftedCueUtc) ?: return false
            return nowEpochMs >= shiftedCueMs
        }
        return nowEpochMs >= cueMs
    }

    /**
     * Returns `true` when the 21:00 streak-at-risk alert threshold (`streakAlertAtUtc`)
     * has been reached for an unchecked active streak, keeping morning/afternoon (`00:00–17:59`)
     * calm and preserving the 18:00–20:59 evening nudge window (`[P2-3]`).
     */
    fun isStreakAlertActive(nowEpochMs: Long): Boolean {
        if (checkedInToday || currentStreak <= 0) return false
        val alertMs = WidgetSnapshot.parseIsoEpochMs(streakAlertAtUtc)
        if (alertMs != null) {
            val midnightMs = WidgetSnapshot.parseIsoEpochMs(midnightRolloverUtc)
            if (midnightMs != null && nowEpochMs >= midnightMs) {
                val zone = resolveZoneId(timezone, utcOffsetMinutes)
                val daysPassed = extraDaysPassed(midnightMs, nowEpochMs, zone)
                val shiftedAlertUtc = shiftIsoUtcByDays(streakAlertAtUtc, daysPassed, zone)
                val shiftedAlertMs = WidgetSnapshot.parseIsoEpochMs(shiftedAlertUtc) ?: return false
                return nowEpochMs >= shiftedAlertMs
            }
            return nowEpochMs >= alertMs
        }
        return atRisk
    }

    fun evaluateAt(nowEpochMs: Long, locale: String? = null): WidgetJourneyItem {
        val midnightMs = WidgetSnapshot.parseIsoEpochMs(midnightRolloverUtc)
        if (midnightMs != null && nowEpochMs >= midnightMs) {
            val zone = resolveZoneId(timezone, utcOffsetMinutes)
            val daysPassed = extraDaysPassed(midnightMs, nowEpochMs, zone)
            val survivedFirstRollover = daysPassed == 1 && checkedInToday
            val newStreak = if (survivedFirstRollover) currentStreak else 0
            val newAtRisk = newStreak > 0
            val rawNewDay = dayNumber + daysPassed
            val cap = totalDays
            val newDayNumber = if (cap != null && cap > 0) minOf(rawNewDay, cap) else rawNewDay
            val rolledStrip = rollWeekStrip(weekStrip, daysPassed, checkedInToday, locale)
            return copy(
                dayNumber = newDayNumber,
                currentStreak = newStreak,
                checkedInToday = false,
                atRisk = newAtRisk,
                eveningCueAtUtc = shiftIsoUtcByDays(eveningCueAtUtc, daysPassed, zone),
                streakAlertAtUtc = shiftIsoUtcByDays(streakAlertAtUtc, daysPassed, zone),
                midnightRolloverUtc = shiftIsoUtcByDays(midnightRolloverUtc, daysPassed, zone),
                reminderAtUtc = shiftIsoUtcByDays(reminderAtUtc, daysPassed, zone),
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
        private val VI_WEEK_LABELS = setOf("T2", "T3", "T4", "T5", "T6", "T7", "CN", "HN")

        internal fun resolveZoneId(timezone: String?, utcOffsetMinutes: Int = 0): ZoneId {
            val trimmed = timezone?.trim()
            if (!trimmed.isNullOrEmpty() && (!trimmed.equals("UTC", ignoreCase = true) || utcOffsetMinutes == 0)) {
                try {
                    return ZoneId.of(trimmed)
                } catch (_: Exception) {
                }
            }
            return try {
                ZoneOffset.ofTotalSeconds(utcOffsetMinutes * 60)
            } catch (_: Exception) {
                ZoneOffset.UTC
            }
        }

        internal fun extraDaysPassed(midnightMs: Long, nowEpochMs: Long, zone: ZoneId): Int {
            if (nowEpochMs < midnightMs) return 0
            return try {
                val midnightZdt = Instant.ofEpochMilli(midnightMs).atZone(zone)
                val nowZdt = Instant.ofEpochMilli(nowEpochMs).atZone(zone)
                val dayDiff = midnightZdt.until(nowZdt, ChronoUnit.DAYS).toInt()
                maxOf(0, dayDiff) + 1
            } catch (_: Exception) {
                ((nowEpochMs - midnightMs) / 86_400_000L).toInt().coerceAtLeast(0) + 1
            }
        }

        internal fun shiftIsoUtcByDays(iso: String?, days: Int, zone: ZoneId): String? {
            if (iso.isNullOrBlank() || days <= 0) return iso
            return try {
                val zdt = Instant.parse(iso.trim()).atZone(zone).plusDays(days.toLong())
                DateTimeFormatter.ISO_INSTANT.format(zdt.toInstant())
            } catch (_: Exception) {
                iso
            }
        }

        internal fun rollWeekStrip(
            strip: List<WidgetWeekDay>,
            daysPassed: Int,
            wasCheckedInBeforeMidnight: Boolean,
            locale: String? = null,
        ): List<WidgetWeekDay> {
            if (strip.isEmpty() || daysPassed <= 0) return strip
            val hasExplicitEnLabel = strip.any {
                it.label == "TD" || it.label.equals("Today", ignoreCase = true)
            }
            val hasExplicitViLabel = strip.any { it.label in VI_WEEK_LABELS }
            val isViStrip = when {
                hasExplicitEnLabel && !hasExplicitViLabel -> false
                hasExplicitViLabel && !hasExplicitEnLabel -> true
                !locale.isNullOrBlank() -> !locale.trim().lowercase(Locale.ROOT).startsWith("en")
                else -> hasExplicitViLabel
            }
            val todayLabel = if (isViStrip) "HN" else "TD"

            val finalized = strip.mapIndexed { index, item ->
                val parsedDate = parseLocalDate(item.date)
                val updatedLabel = if (item.label == "HN" || item.label == "TD" || item.label.equals("Today", ignoreCase = true)) {
                    parsedDate?.let { weekdayLabelFor(it.dayOfWeek, isViStrip) } ?: item.label
                } else {
                    item.label
                }
                if (index == strip.lastIndex && (item.state == "today" || item.state == "done")) {
                    item.copy(
                        label = updatedLabel,
                        state = if (wasCheckedInBeforeMidnight) "done" else "missed",
                    )
                } else if (updatedLabel != item.label) {
                    item.copy(label = updatedLabel)
                } else {
                    item
                }
            }
            if (daysPassed >= strip.size) {
                val baseDate = parseLocalDate(strip.last().date)
                return finalized.mapIndexed { idx, item ->
                    val isTodaySlot = idx == finalized.lastIndex
                    val slotDate = baseDate?.plusDays((daysPassed - (finalized.lastIndex - idx)).toLong())
                    item.copy(
                        date = slotDate?.format(DateTimeFormatter.ISO_LOCAL_DATE) ?: item.date,
                        day = slotDate?.dayOfMonth ?: item.day,
                        label = if (isTodaySlot) {
                            todayLabel
                        } else {
                            slotDate?.let { weekdayLabelFor(it.dayOfWeek, isViStrip) } ?: item.label
                        },
                        state = if (isTodaySlot) "today" else "missed",
                    )
                }
            }
            val lastDate = parseLocalDate(strip.last().date)
            val kept = finalized.drop(daysPassed).toMutableList()
            for (step in 1..daysPassed) {
                val nextDate = lastDate?.plusDays(step.toLong())
                val isTodaySlot = step == daysPassed
                val slotLabel = if (isTodaySlot) {
                    todayLabel
                } else {
                    nextDate?.let { weekdayLabelFor(it.dayOfWeek, isViStrip) } ?: todayLabel
                }
                kept.add(
                    WidgetWeekDay(
                        date = nextDate?.format(DateTimeFormatter.ISO_LOCAL_DATE) ?: "",
                        day = nextDate?.dayOfMonth ?: ((strip.last().day + step - 1) % 31 + 1),
                        label = slotLabel,
                        state = if (isTodaySlot) "today" else "missed",
                    ),
                )
            }
            return kept
        }

        private fun parseLocalDate(raw: String): LocalDate? {
            if (raw.isBlank()) return null
            return try {
                LocalDate.parse(raw, DateTimeFormatter.ISO_LOCAL_DATE)
            } catch (_: Exception) {
                null
            }
        }

        private fun weekdayLabelFor(dayOfWeek: DayOfWeek, isVi: Boolean): String {
            return if (isVi) {
                when (dayOfWeek) {
                    DayOfWeek.MONDAY -> "T2"
                    DayOfWeek.TUESDAY -> "T3"
                    DayOfWeek.WEDNESDAY -> "T4"
                    DayOfWeek.THURSDAY -> "T5"
                    DayOfWeek.FRIDAY -> "T6"
                    DayOfWeek.SATURDAY -> "T7"
                    DayOfWeek.SUNDAY -> "CN"
                }
            } else {
                when (dayOfWeek) {
                    DayOfWeek.MONDAY -> "M"
                    DayOfWeek.TUESDAY -> "T"
                    DayOfWeek.WEDNESDAY -> "W"
                    DayOfWeek.THURSDAY -> "T"
                    DayOfWeek.FRIDAY -> "F"
                    DayOfWeek.SATURDAY -> "S"
                    DayOfWeek.SUNDAY -> "S"
                }
            }
        }

        fun fromJson(obj: JSONObject): WidgetJourneyItem {
            val stripArr = obj.optArrayOrNull("weekStrip") ?: JSONArray()
            val strip = buildList {
                for (i in 0 until stripArr.length()) {
                    stripArr.optJSONObject(i)?.let { add(WidgetWeekDay.fromJson(it)) }
                }
            }
            return WidgetJourneyItem(
                id = obj.optCleanString("id", ""),
                title = obj.optCleanString("title", ""),
                kind = obj.optCleanString("kind", "solo"),
                skinId = obj.optCleanString("skinId", "minimal"),
                colorVariant = obj.optIntCompat("colorVariant", 0),
                typeIcon = obj.optCleanString("typeIcon", "type-custom"),
                timezone = obj.optCleanString("timezone", "UTC"),
                utcOffsetMinutes = obj.optIntCompat("utcOffsetMinutes", 0),
                pinned = obj.optBooleanCompat("pinned", false),
                dayNumber = obj.optIntCompat("dayNumber", 1),
                totalDays = obj.optPositiveIntOrNull("totalDays"),
                currentStreak = obj.optIntCompat("currentStreak", 0),
                bestStreak = obj.optIntCompat("bestStreak", 0),
                checkedInToday = obj.optBooleanCompat("checkedInToday", false),
                atRisk = obj.optBooleanCompat("atRisk", false),
                eveningCueAtUtc = obj.optNullableString("eveningCueAtUtc"),
                streakAlertAtUtc = obj.optNullableString("streakAlertAtUtc"),
                midnightRolloverUtc = obj.optNullableString("midnightRolloverUtc"),
                reminderAtUtc = obj.optNullableString("reminderAtUtc"),
                heroThumbFile = obj.optNullableString("heroThumbFile"),
                heroThumbBlurred = obj.optBooleanCompat("heroThumbBlurred", false),
                weekStrip = strip,
                isSensitive = obj.optBooleanCompat("isSensitive", false),
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
            date = obj.optCleanString("date", ""),
            day = obj.optIntCompat("day", 1),
            label = obj.optCleanString("label", ""),
            state = obj.optCleanString("state", "future"),
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
    val totalDays: Int?,
    val doneCount: Int,
    val memberCount: Int,
    val meCheckedInToday: Boolean,
    val midnightRolloverUtc: String?,
    val members: List<WidgetSquadMember>,
) {
    val isOpenEnded: Boolean
        get() = totalDays == null || totalDays <= 0

    // Cached snapshots from older versions may contain only the joined sides.
    val coupleSlots: List<WidgetSquadMember>
        get() = List(2) { index ->
            members.getOrNull(index) ?: WidgetSquadMember(
                displayName = "",
                initial = "",
                avatarColorIndex = 0,
                isMe = false,
                checkedInToday = false,
                streak = 0,
                avatarFile = null,
                todayThumbFile = null,
                todayThumbBlurred = false,
                slotId = "vacant-$index",
                isVacant = true,
            )
        }

    fun evaluateAt(
        nowEpochMs: Long,
        timezone: String? = null,
        utcOffsetMinutes: Int = 0,
    ): WidgetSquadItem {
        val midnightMs = WidgetSnapshot.parseIsoEpochMs(midnightRolloverUtc)
        if (midnightMs != null && nowEpochMs >= midnightMs) {
            val zone = WidgetJourneyItem.resolveZoneId(timezone, utcOffsetMinutes)
            val daysPassed = WidgetJourneyItem.extraDaysPassed(midnightMs, nowEpochMs, zone)
            val rawNewDay = dayNumber + daysPassed
            val cap = totalDays
            val newDayNumber = if (cap != null && cap > 0) minOf(rawNewDay, cap) else rawNewDay
            return copy(
                dayNumber = newDayNumber,
                doneCount = 0,
                meCheckedInToday = false,
                midnightRolloverUtc = WidgetJourneyItem.shiftIsoUtcByDays(midnightRolloverUtc, daysPassed, zone),
                members = members.map { member ->
                    member.copy(
                        checkedInToday = false,
                        streak = if (daysPassed == 1 && member.checkedInToday) member.streak else 0,
                        todayThumbFile = null,
                        todayThumbBlurred = false,
                    )
                },
            )
        }
        return this
    }

    companion object {
        fun fromJson(obj: JSONObject): WidgetSquadItem {
            val membersArr = obj.optArrayOrNull("members") ?: JSONArray()
            val members = buildList {
                for (i in 0 until membersArr.length()) {
                    membersArr.optJSONObject(i)?.let { add(WidgetSquadMember.fromJson(it)) }
                }
            }
            return WidgetSquadItem(
                journeyId = obj.optCleanString("journeyId", ""),
                title = obj.optCleanString("title", ""),
                skinId = obj.optCleanString("skinId", "squad"),
                colorVariant = obj.optIntCompat("colorVariant", 0),
                typeIcon = obj.optCleanString("typeIcon", "type-study"),
                isCouple = obj.optBooleanCompat("isCouple", false),
                dayNumber = obj.optIntCompat("dayNumber", 1),
                totalDays = obj.optPositiveIntOrNull("totalDays"),
                doneCount = obj.optIntCompat("doneCount", 0),
                memberCount = obj.optIntCompat("memberCount", members.size),
                meCheckedInToday = obj.optBooleanCompat("meCheckedInToday", false),
                midnightRolloverUtc = obj.optNullableString("midnightRolloverUtc"),
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
    val slotId: String? = null,
    val isVacant: Boolean = false,
) {
    companion object {
        fun fromJson(obj: JSONObject): WidgetSquadMember {
            val name = obj.optCleanString("displayName", "")
            val fallbackInitial = name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "?"
            return WidgetSquadMember(
                displayName = name,
                initial = obj.optCleanString("initial", fallbackInitial),
                avatarColorIndex = obj.optIntCompat("avatarColorIndex", 0),
                isMe = obj.optBooleanCompat("isMe", false),
                checkedInToday = obj.optBooleanCompat("checkedInToday", false),
                streak = obj.optIntCompat("streak", 0),
                avatarFile = obj.optNullableString("avatarFile"),
                todayThumbFile = obj.optNullableString("todayThumbFile"),
                todayThumbBlurred = obj.optBooleanCompat("todayThumbBlurred", false),
                slotId = obj.optNullableString("slotId"),
                isVacant = obj.optBooleanCompat("isVacant", false),
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
    val redactLockScreenTitles: Boolean? = null,
    val isSensitive: Boolean = false,
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
            val journeyId = obj.optCleanString("journeyId", "")
            val deadlineUtc = obj.optCleanString("deadlineUtc", "")
            val celebrate = obj.optBooleanCompat("celebrateAndDismiss", false)
            if (journeyId.isBlank() && !celebrate) return null
            val redactLockScreen = when {
                obj.has("redactLockScreenTitles") && !obj.isNull("redactLockScreenTitles") ->
                    obj.optBoolean("redactLockScreenTitles", false)
                obj.has("redactTitleOnLockScreen") && !obj.isNull("redactTitleOnLockScreen") ->
                    obj.optBoolean("redactTitleOnLockScreen", false)
                else -> null
            }
            return WidgetLiveWindow(
                windowKey = obj.optCleanString("windowKey", ""),
                journeyId = journeyId,
                journeyTitle = obj.optCleanString("journeyTitle", ""),
                skinId = obj.optCleanString("skinId", "squad"),
                colorVariant = obj.optIntCompat("colorVariant", 0),
                typeIcon = obj.optCleanString("typeIcon", "type-study"),
                currentStreak = obj.optIntCompat("currentStreak", 0),
                atRisk = obj.optBooleanCompat("atRisk", false),
                pendingCount = obj.optIntCompat("pendingCount", 0),
                completedCount = obj.optIntCompat("completedCount", 0),
                totalActiveCount = obj.optIntCompat("totalActiveCount", 1),
                windowStartUtc = obj.optCleanString("windowStartUtc", ""),
                deadlineUtc = deadlineUtc,
                celebrateAndDismiss = celebrate,
                redactLockScreenTitles = redactLockScreen,
                isSensitive = obj.optBooleanCompat("isSensitive", false),
            )
        }

        fun fromMap(rawMap: Map<*, *>): WidgetLiveWindow {
            val nested = rawMap["liveWindow"] as? Map<*, *>
            val map: Map<*, *> = if (nested != null) {
                buildMap<Any?, Any?> {
                    putAll(rawMap)
                    putAll(nested)
                }
            } else {
                rawMap
            }
            val json = JSONObject()
            for ((k, v) in map) {
                if (k is String && v != null && v != JSONObject.NULL) {
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
                redactLockScreenTitles = (map["redactLockScreenTitles"] as? Boolean)
                    ?: (map["redactTitleOnLockScreen"] as? Boolean),
                isSensitive = (map["isSensitive"] as? Boolean) ?: false,
            )
        }
    }
}

/**
 * Explicit 4-state resolution for `OurneyTodayWidget` and `OurneyStreakWidget`
 * (§A.3), distinguishing a freshly dropped widget before the first app sync
 * ([Unsynced]) from a signed-out account ([SignedOut]) and a signed-in account
 * with zero journeys ([NoJourneys]).
 */
sealed interface JourneyWidgetCardState {
    data object Unsynced : JourneyWidgetCardState
    data object SignedOut : JourneyWidgetCardState
    data object NoJourneys : JourneyWidgetCardState
    data class Ready(
        val journey: WidgetJourneyItem,
        val isPinned: Boolean,
        val pendingIndex: Int,
        val pendingCount: Int,
    ) : JourneyWidgetCardState
}

/**
 * Explicit 5-state resolution for `OurneySquadWidget` (§A.3, Rank 5), adding
 * [SoloOnlyAccount] when a signed-in user has active solo journeys but zero
 * group/couple journeys.
 */
sealed interface SquadWidgetCardState {
    data object Unsynced : SquadWidgetCardState
    data object SignedOut : SquadWidgetCardState
    data object NoJourneysAtAll : SquadWidgetCardState
    data class SoloOnlyAccount(val soloCount: Int) : SquadWidgetCardState
    data class Ready(
        val squad: WidgetSquadItem,
        val isPinned: Boolean,
    ) : SquadWidgetCardState
}

/**
 * Mutable interactive widget state stored in `state.json` so Glance
 * `ActionCallback`s, `OurneyWidgetConfigureActivity`, and `CheckInWindowReceiver`
 * never mutate `snapshot_v1.json`.
 */
data class WidgetMutableState(
    val selectedTodayIndex: Int = 0,
    val dismissedWindowKey: String? = null,
    val dismissedWindowDate: String? = null,
    val widgetSelections: Map<Int, String> = emptyMap(),
) {
    fun selectionFor(appWidgetId: Int): String =
        widgetSelections[appWidgetId]?.takeIf { it.isNotBlank() } ?: WidgetSnapshot.AUTO_SELECTION_ID

    fun toJsonString(): String {
        val obj = JSONObject()
        obj.put("selectedTodayIndex", selectedTodayIndex)
        if (!dismissedWindowKey.isNullOrBlank()) {
            obj.put("dismissedWindowKey", dismissedWindowKey)
        }
        if (!dismissedWindowDate.isNullOrBlank()) {
            obj.put("dismissedWindowDate", dismissedWindowDate)
        }
        if (widgetSelections.isNotEmpty()) {
            val selObj = JSONObject()
            for ((widgetId, selection) in widgetSelections) {
                if (widgetId > 0 && selection.isNotBlank()) {
                    selObj.put(widgetId.toString(), selection)
                }
            }
            if (selObj.length() > 0) {
                obj.put("widgetSelections", selObj)
            }
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
            val selObj = obj.optObjectOrNull("widgetSelections")
            val selections = buildMap<Int, String> {
                if (selObj != null) {
                    val keys = selObj.keys()
                    while (keys.hasNext()) {
                        val rawKey = keys.next()
                        val id = rawKey.toIntOrNull() ?: continue
                        val sel = selObj.optCleanString(rawKey, "")
                        if (id > 0 && sel.isNotBlank()) {
                            put(id, sel)
                        }
                    }
                }
            }
            return WidgetMutableState(
                selectedTodayIndex = obj.optIntCompat("selectedTodayIndex", 0).coerceAtLeast(0),
                dismissedWindowKey = obj.optNullableString("dismissedWindowKey"),
                dismissedWindowDate = obj.optNullableString("dismissedWindowDate"),
                widgetSelections = selections,
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

/**
 * Safe `org.json.JSONObject` accessors that check [JSONObject.has] and
 * [JSONObject.isNull] BEFORE reading values.
 *
 * On Android (`android.jar`), calling `optString(key, "")` on a key whose value
 * is `JSONObject.NULL` returns the 4-character literal `"null"` (AOSP 36908090),
 * whereas Dart omits optional keys or may pass `null`. Guarding with
 * `has(key) && !isNull(key)` prevents `"null"` string corruption across both
 * absent keys and explicit `null` values.
 */
private fun JSONObject.optNullableString(key: String): String? {
    if (!has(key) || isNull(key)) return null
    val value = optString(key, "").trim()
    return value.takeIf { it.isNotEmpty() && !it.equals("null", ignoreCase = true) }
}

private fun JSONObject.optCleanString(key: String, fallback: String = ""): String {
    if (!has(key) || isNull(key)) return fallback
    val value = optString(key, fallback)
    if (value.isBlank() || value.equals("null", ignoreCase = true)) return fallback
    return value
}

private fun JSONObject.optIntCompat(key: String, fallback: Int): Int {
    if (!has(key) || isNull(key)) return fallback
    return optInt(key, fallback)
}

private fun JSONObject.optPositiveIntOrNull(key: String): Int? {
    if (!has(key) || isNull(key)) return null
    val value = optInt(key, 0)
    return value.takeIf { it > 0 }
}

private fun JSONObject.optBooleanCompat(key: String, fallback: Boolean): Boolean {
    if (!has(key) || isNull(key)) return fallback
    return optBoolean(key, fallback)
}

private fun JSONObject.optObjectOrNull(key: String): JSONObject? {
    if (!has(key) || isNull(key)) return null
    return optJSONObject(key)
}

private fun JSONObject.optArrayOrNull(key: String): JSONArray? {
    if (!has(key) || isNull(key)) return null
    return optJSONArray(key)
}
