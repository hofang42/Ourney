# journeys (B4)

Journeys tab, create flow, journey detail/timeline and the day photo viewer.

## Routes (`routes.dart`)

| Path | Screen | Navigator |
|---|---|---|
| `/journeys` (`AppRoutes.journeys`) | `JourneysListScreen` | Journeys tab |
| `/journeys/new` (`AppRoutes.journeyNew`) | `TemplatePickerScreen` | root (covers the bar) |
| `/journeys/new/:template` (`JourneysPaths.newFromTemplate`) | `CreateJourneyScreen`, `:template` = `TemplateId.wireName` | root |
| `/journey/:id` (`AppRoutes.journey`) | `JourneyDetailScreen` | Journeys tab |
| `/journey/:id/day/:date` (`JourneysPaths.day`) | `DayViewerScreen`, `:date` = `YYYY-MM-DD` | root |

Outgoing links: `/capture` (check in now), `AppRoutes.share(id)` (C2),
`AppRoutes.groups` (group journeys; group screens belong to C1).

## "Check in now" hand-off to the camera (B3)

`JourneyDetailScreen.checkInNow` does **both**, in this order:

1. writes the journey id to shared preferences under
   **`camera.lastJourneyId`** (`lastJourneyPrefsKey`), the same key the
   camera uses to remember the last journey (FR-C1);
2. `context.go('/capture?journeyId=<id>')` (`captureJourneyParam`,
   `JourneysPaths.captureFor`).

The camera can rely on the preference alone; the query parameter is there
for the case where the camera wants to tell "opened for this journey"
apart from "opened from the tab".

## Repository calls

`JourneyRepository`: `watchActive`, `watch`, `watchMyMembership`, `create`,
`updateMyMembership` (after create: `hideMetric` / `blurMedia` per FR-B7, and
the privacy switches on the detail screen), `end`, `archive`, `delete`.
`CheckInRepository`: `watchForJourney(id, userId:)` (caller's own check-ins).
`MediaStore`: `localFileFor(thumbPath | photoPath)`.

Errors are mapped from `OurneyException.error` (`limit`, `not_alone`,
`forbidden`, `ended`, `not_found`, `invalid`, `offline`), see
`ui/journey_errors.dart`.

## Rules

* Streaks, % and day N/M come from `computeMemberStreak` in the journey's
  time zone (`domain/journey_progress.dart`), never stored.
* 3 active journeys: the FAB shows a friendly dialog (`canCreateJourney`);
  the server's `limit` error shows the same dialog.
* Ended journeys are read-only (no check-in button, banner). Archive is only
  offered for ended journeys; delete only for the owner (`not_alone` from the
  server for groups with other members).
* While the data layer is not wired (repositories throw
  `UnimplementedError`), the list/detail fall back to `PlaceholderScreen`.
