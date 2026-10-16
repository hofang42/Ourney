# Safety (C3): report, block, EULA, privacy, contact

FR-F1..F3. Everything lives under `/safety`, which the router lets through
before onboarding and sign-in.

## Routes (`SafetyPaths`, `lib/features/safety/safety_paths.dart`)

| Path | Builder | Purpose |
|---|---|---|
| `/safety` | `SafetyPaths.hub` | Hub: terms, privacy, contact, blocked people (signed in only) |
| `/safety/eula` | `SafetyPaths.eula` | Terms of use (zero tolerance, Guideline 1.2) |
| `/safety/eula/accept?from=<path>` | `SafetyPaths.eulaAccept` | EULA gate; on accept goes to `from` (safe in-app paths only) or `/capture` |
| `/safety/privacy` | `SafetyPaths.privacy` | Privacy policy |
| `/safety/contact` | `SafetyPaths.contact` | Contact (mailto + copy) |
| `/safety/blocked` | `SafetyPaths.blocked` | Blocked people, unblock |
| `/safety/report/checkin/<checkInId>?userId=&name=` | `SafetyPaths.reportCheckIn(id, userId:, name:)` | Report a check-in. `userId`/`name` (author) are optional: they add "also block" after sending |
| `/safety/report/user/<userId>?name=` | `SafetyPaths.reportUser(id, name:)` | Report a user |
| `/safety/block/<userId>?name=` | `SafetyPaths.block(id, name:)` | Block confirmation page |

Report and block pages pop with `true` on success (`context.push<bool>(...)`).
In local-only mode they show the "needs server" state.

## Functions (preferred from other screens, e.g. Groups)

```dart
import 'package:ourney/features/safety/ui/report_form.dart';   // showReportSheet
import 'package:ourney/features/safety/ui/block_dialogs.dart';  // confirmBlock, confirmUnblock

final reported = await showReportSheet(context, checkInId: c.id, userId: c.userId, name: displayName);
final reported = await showReportSheet(context, userId: m.userId, name: m.displayName);
final blocked  = await confirmBlock(context, userId: m.userId, name: m.displayName);
```

All need only a `BuildContext` under the app `ProviderScope`; they show their
own snack bars and never throw. Pass the display name: the contract streams
only blocked ids, so the name is remembered on this device
(`safety.blockedNames`) for the blocked list.

## Providers (`data/safety_providers.dart`)

| Provider | Use |
|---|---|
| `hiddenCheckInIdsProvider` | `Set<String>` of check-ins reported this session. **Filter group feeds with it** so reported content disappears at once (FR-F2); the server also hides it for the reporter. |
| `blockedUserIdsProvider` | `SafetyRepository.watchBlockedIds()` |
| `eulaAcceptedProvider` | `bool`, prefs key `safety.eulaAccepted`; `.notifier.accept()` / `.reset()` |
| `safetyActionsProvider` | `report`, `block`, `unblock` (used by the UI above) |

Repository calls: `SafetyRepository.report(checkInId | userId, reason, note)`
(note trimmed, empty -> null, max 500), `block`, `unblock`, `watchBlockedIds`.
Errors map `rate_limited`, `not_found`, `invalid`, `offline` to messages.

## EULA gate (wired in lib/app, Wave D)

Apple 1.2 requires accepting terms before seeing user content.
`resolveRedirect` (`lib/app/redirect.dart`, after the auth gate): when
`auth == AuthStatus.signedIn && !eulaAccepted` and the path is not under
`/safety`, it redirects to `/safety/eula/accept?from=<target>`;
`routerProvider` listens to `eulaAcceptedProvider`. Local-only mode has no
other users, so it has no gate. Account deletion
(`DeleteAccountDialog`) calls `eulaAcceptedProvider.notifier.reset()`.

Groups: `groupSafetyHooksProvider` defaults to `safetyGroupHooks`
(`showReportSheet` / `confirmBlock`), and the group "Today" screen filters
`hiddenCheckInIdsProvider`.

## Owner TODOs

- `kSupportEmail = 'support@ourney.app'` is a placeholder: confirm the real
  mailbox before release.
- Legal texts are in `l10n/safety_{vi,en}.arb` (`safety_eula*`,
  `safety_privacy*`); bump `kLegalLastUpdated` when they change. They need
  an owner/legal review.
