# 109 - Hourly background refresh

## Goal

CloudKit silent push reaches devices roughly half the time in practice, so a
caregiver's view of "what's the latest" can drift. Add an hourly opportunistic
background refresh that runs alongside push so the on-device data has a second,
independent chance to catch up while the app is suspended.

## Approach

Use the modern `BackgroundTasks` framework (`BGAppRefreshTask`). Keep the
framework import out of feature/preview code by introducing a protocol seam
and a use case, mirroring the `LocalNotificationManaging`/`SystemLocalNotificationManager`
pattern already used in this project.

1. Declare a single permitted task identifier
   (`com.adappt.BabyTracker.backgroundRefresh`) in `Info.plist` and add the
   `fetch` background mode so iOS will run it.
2. In `BabyTrackerFeature`, add:
   - `BackgroundRefreshScheduling` — protocol exposing
     `registerLaunchHandler(_:)` and `scheduleNext()`.
   - `BackgroundRefreshing` — protocol AppModel adopts so the use case
     doesn't depend on the full feature graph.
   - `PerformBackgroundRefreshUseCase` — runs the same sync path used by
     silent push and reports a Bool.
   - `NoOpBackgroundRefreshScheduler` — for previews and tests.
3. In the app target, add `SystemBackgroundRefreshScheduler` — the only place
   that imports `BackgroundTasks`. It registers the launch handler with
   `BGTaskScheduler.shared`, schedules requests ~1 hour out, and on each run
   immediately schedules the next request and completes the task based on
   the use case result.
4. `AppContainer` exposes `backgroundRefreshScheduler` and selects between
   the system and no-op implementations using the existing
   `usesUnavailableCloudKitClient` flag.
5. `BabyTrackerApp.init` registers the launch handler with the use case;
   `AppRootView` calls `scheduleNext()` from its existing scenePhase change.

iOS controls actual run timing — the 1-hour value is a hint. In practice it
fires opportunistically a few times a day depending on usage, battery, and
Low Power Mode. That is exactly the gap-filling behaviour we want layered on
top of push.

## Notes

- `BGTaskScheduler.register` must be called before `application(_:didFinishLaunchingWithOptions:)`
  returns. Calling it from `BabyTrackerApp.init` satisfies that ordering.
- The protocol seam keeps the `BackgroundTasks` import out of
  `BabyTrackerFeature` and out of `#Preview` blocks, matching how
  `LocalNotificationManaging` keeps `UserNotifications` out of feature code.
- Reusing `refreshAfterRemoteNotification` via `BackgroundRefreshing` keeps
  reminder rescheduling correct via `scheduleRemoteSyncNotificationIfNeeded()`.

- [x] Complete
