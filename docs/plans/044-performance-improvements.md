## Goal

Fix two distinct performance bottlenecks reported in issue #99.

---

## Part A — Import performance (issue #105)

**Problem:** `ImportEventsUseCase.execute()` is synchronous on `@MainActor`. Importing 400+ events runs a tight loop that blocks the UI for the full duration. The indeterminate spinner gives no feedback.

**Approach:**

1. Drop `UseCase` protocol conformance from `ImportEventsUseCase` — it is a long-running batch operation, not a single atomic action.
2. Change `execute` to `async throws -> CSVImportResult` with an `onProgress: ((Int, Int) -> Void)?` parameter (completed, total).
3. Call `await Task.yield()` every 20 events so the run loop can breathe and SwiftUI state updates can land.
4. Add `ImportProgress: Equatable, Sendable` with `completed: Int` and `total: Int` to `BabyTrackerFeature`.
5. Change `.importing` on `CSVImportState` and `NestImportState` to `.importing(ImportProgress)`.
6. Update `AppModel.confirmImport()` and the Nest equivalent to initialise `ImportProgress(completed: 0, total: n)` then pass an `onProgress` closure that updates state.
7. Update `ChildProfileImportView` and `ChildProfileNestImportView` to show a determinate `ProgressView(value:total:)` with an event count label instead of the indeterminate spinner. Update `#Preview` to cover the progress state.

**Files:**
- `Packages/BabyTrackerDomain/Sources/BabyTrackerDomain/UseCases/ImportEventsUseCase.swift`
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/CSVImportState.swift`
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/NestImportState.swift`
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift`
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildProfileImportView.swift`
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildProfileNestImportView.swift`

---

## Part B — Sync performance (issue #106)

**Problem:** `shouldForceOwnerSharedZoneReconciliation` fires on every `refreshAfterLocalWrite()`. For a child zone with a CKShare it makes a CloudKit network request then forces a full zone snapshot pull of all records before pushing. Logs show "pulling down all files" on every write.

**Background:** Added in plan 022 to fix caregiver edits not always appearing in incremental pulls on the owner's device. The fix is correct for `launch`, `foreground`, and `remoteNotification` syncs but is unnecessarily expensive on `localWrite`.

**Approach:**

1. Add a `skipReconciliation: Bool` parameter to `pullKnownChildZones(forceFullFetch:skipReconciliation:)` and `pushPendingChanges(skipReconciliation:)` in `CloudKitSyncEngine`.
2. In `refresh(reason:)`, pass `skipReconciliation: reason == .localWrite`.
3. Guard the `shouldForceOwnerSharedZoneReconciliation` branch with `!skipReconciliation`.

Incremental pulls via change tokens continue to work on the `localWrite` path. Reconciliation still fires on `launch`, `foreground`, and `remoteNotification`.

**Files:**
- `Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift`

---

## Verification

**Part A:**
1. Import a CSV with 400+ events — progress bar should advance incrementally.
2. App remains responsive during import.
3. Complete screen shows the correct imported count.
4. Existing import tests pass.

**Part B:**
1. Log a single event on a device with a shared child zone.
2. AppLogger should no longer show a full `pullZoneSnapshot` on a local-write refresh.
3. Foregrounding the app still triggers reconciliation and caregiver edits appear.
4. Existing sync tests pass.

- [x] Complete
