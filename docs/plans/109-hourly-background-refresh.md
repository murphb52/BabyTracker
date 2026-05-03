# 109 - Hourly background refresh

## Goal

CloudKit silent push reaches devices roughly half the time in practice, so a
caregiver's view of "what's the latest" can drift. Add an hourly opportunistic
background refresh that runs alongside push so the on-device data has a second,
independent chance to catch up while the app is suspended.

## Approach

Use the modern `BackgroundTasks` framework (`BGAppRefreshTask`). Reuse the
existing remote-notification refresh entry point so we get sync, reminder
rescheduling, and live-activity reconciliation for free.

1. Declare a single permitted task identifier
   (`com.adappt.BabyTracker.backgroundRefresh`) in `Info.plist` and add the
   `fetch` background mode so iOS will run it.
2. Add a small `BackgroundAppRefreshScheduler` in the app target that:
   - registers the launch handler with `BGTaskScheduler.shared` at launch,
   - schedules the next request with an `earliestBeginDate` ~1 hour out,
   - on launch handler invocation: runs the refresh closure, completes the
     `BGTask` with success based on the resulting `SyncStatusSummary`, and
     immediately schedules the next request.
3. Wire the refresh closure in `BabyTrackerApp.init` to call
   `appModel.refreshAfterRemoteNotification(isAppInBackground: true)` — the
   same path silent push already uses (`AppModel.swift:302`).
4. Schedule the next request when the scene transitions to `.background`
   (`AppRootView.swift:84`), so each foreground session leaves a pending
   request behind.

iOS controls actual run timing — the 1-hour value is a hint. In practice it
fires opportunistically a few times a day depending on usage, battery, and
Low Power Mode. That is exactly the gap-filling behaviour we want layered on
top of push.

## Notes

- `BGTaskScheduler.register` must be called before `application(_:didFinishLaunchingWithOptions:)`
  returns. Calling it from `BabyTrackerApp.init` satisfies that ordering.
- No new abstraction over `BGTaskScheduler` itself: the plumbing is short and
  matches the existing `CloudKitRemoteNotificationBridge` precedent
  (no protocol seam, no unit tests for OS glue).
- Reusing `refreshAfterRemoteNotification` keeps reminder rescheduling correct
  via `scheduleRemoteSyncNotificationIfNeeded()` (`AppModel.swift:304`).

- [x] Complete
