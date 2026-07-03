# 111 Live Activity rebuild — fix permanent staleness

## Problem

The feed Live Activity keeps going stale: after a while the lock-screen card
freezes on old data and eventually disappears.

Root cause: **iOS only applies `Activity.update` for roughly 8 hours after
`Activity.request`, and removes the activity entirely after ~12 hours.** The
existing implementation requests the activity once and then only ever updates
it. The update budget is never renewed, so a card that is meant to live for
days silently stops accepting updates ~8 hours after it was started — every
later foreground refresh and hourly background refresh "succeeds" while the
lock screen shows frozen data.

Secondary issues in the old plumbing:

- `synchronize` cancelled the in-flight reconcile task on every call, so an
  ActivityKit write could be abandoned midway.
- The manager had no foreground awareness; call sites had to know that
  `Activity.request` only works in the foreground (see plan 103 for the
  history of bugs this caused).
- A dead snapshot-cache layer (`FeedLiveActivitySnapshotCaching` and friends)
  remained in the tree with no consumers.

## Approach

Remove all app-side Live Activity plumbing and rebuild it. The widget UI
(`Baby Tracker Live Activities/*`), the `FeedLiveActivityAttributes` contract,
the deep link, and the preference toggle are kept.

### Removed

- `BuildFeedLiveActivitySnapshotUseCase`, `UpdateFeedLiveActivityUseCase`,
  `ResetFeedLiveActivityUseCase`
- `FeedLiveActivitySnapshotCaching`, `InMemoryFeedLiveActivitySnapshotCache`,
  `UserDefaultsFeedLiveActivitySnapshotCache` (dead code)
- The old `FeedLiveActivityManager` and the `hasRunningActivity` protocol
  requirement
- Duplicated/obsolete tests for the removed use cases

### Rebuilt

1. **`SyncFeedLiveActivityUseCase`** (feature package) — single entry point
   that builds a `FeedLiveActivitySnapshot` from the current profile state and
   hands it to the manager. A `nil` snapshot (disabled, no child, no feed data)
   ends the activity.
2. **`FeedLiveActivityManaging`** — slimmed to one requirement:
   `synchronize(with:)`. The manager owns all ActivityKit policy.
3. **`FeedLiveActivityManager`** (app target) — fresh implementation:
   - **Serialized, latest-wins reconciles.** ActivityKit writes are always
     awaited to completion; a newer snapshot replaces the pending one instead
     of cancelling mid-write.
   - **Lifetime renewal (the staleness fix).** `FeedLiveActivityAttributes`
     gains an optional `startedAt`. When the app is in the foreground and the
     running activity is older than one hour, the manager ends it and requests
     a fresh one, renewing iOS's ~8-hour update budget on every realistic
     foreground visit. Activities from older builds (`startedAt == nil`) are
     restarted on the first foreground reconcile.
   - **Foreground gating inside the manager.** `Activity.request` is only
     attempted while the app is not in the background; background reconciles
     (hourly refresh, silent push, `appDidEnterBackground`) update the running
     activity only.
   - **Dedup against ActivityKit itself.** Updates compare against
     `activity.content.state`, never a shadow cache.
4. **Triggers unchanged**: every successful foreground `refresh`, entering the
   background, remote-notification refresh, and the settings toggle.

### Known limit

Without push-token updates (server infrastructure we don't have), an activity
still dies if the app is untouched for over ~8 hours. This rebuild guarantees
the budget is renewed on every app visit, which is the best a local-only
implementation can do.

- [x] Complete
