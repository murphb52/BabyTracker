# CloudKit Sync — Architecture, Debugging & Fixes

> Session notes covering the CloudKit sync layer, share acceptance investigation, and bugs fixed.

---

## Project Context

Baby Tracker is an iOS app built with SwiftUI and SwiftData. It uses a **custom CloudKit sync engine** (not `NSPersistentCloudKitContainer`) for full control over multi-child partitioning, sharing, and conflict resolution. The sync code lives in the `BabyTrackerSync` Swift package.

---

## CloudKit Architecture

### Single Container, Zone-Per-Child

All data lives in one CloudKit container: `iCloud.com.adappt.BabyTracker`.

Children are not separated by container — they are separated by **CKRecordZone**. Each child gets its own zone named `child-{UUID}`. This means:

- Multiple children are fully supported in the data layer
- Each child's data (events, memberships, users) is scoped to its zone
- Sharing is done at the zone level using `CKShare`

### Private vs Shared Database

| Scenario | Database Scope | How it gets there |
|---|---|---|
| You own the child | `.private` | Zone created on your device, pushed to your private DB |
| Someone shared a child with you | `.shared` | Zone accepted via `CKShare`, accessed via shared DB |

Each child's sync context is stored locally as `CloudKitChildContext`, which tracks the `zoneID` and `databaseScope`. This is how the engine knows whether to read/write the private or shared database for each child.

### Record Types

Every record lives inside its child's zone:

- `Child` — profile data (name, birth date)
- `UserIdentity` — user display name and CloudKit record name
- `Membership` — relationship between a user and a child (role: owner/caregiver, status: active/invited/removed)
- `BreastFeedEvent`, `BottleFeedEvent`, `SleepEvent`, `NappyEvent`

### Sync Engine Flow (on launch and foreground)

```
refresh(reason:)
 ├── removeLegacyPlaceholderCaregivers()
 ├── client.accountStatus()                    — check iCloud is signed in
 ├── client.userRecordID()                     — get current user's CK record ID
 ├── childRepository.linkLocalUser(...)        — merge local identity with CK identity
 ├── pullSharedDatabaseChanges()               — check shared DB for new/removed zones
 │    └── pullZoneSnapshot(context:)           — for each modified shared zone
 ├── pullKnownChildZones()                     — pull incremental changes for all known zones
 │    └── pullZoneSnapshot(context:)           — per child
 └── pushPendingChanges()                      — push any locally-changed records
      └── pushZoneSnapshot(for:context:)       — per child with pending records
```

### Conflict Resolution

Last-write-wins based on `updatedAt` timestamp on event records. The engine compares local vs remote `EventMetadata` and keeps whichever was updated more recently. Non-event records (child profile, memberships, users) are always pushed local-over-remote.

### Share Acceptance Flow

When another user accepts a CloudKit share:

```
UIWindowSceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)
 └── CloudKitShareAcceptanceBridge.handle(metadata:)
      └── ShareAcceptanceHandler.accept(metadata:)
           └── CloudKitSyncEngine.accept(metadata:)
                ├── client.accept([metadata])            — register with CloudKit
                ├── refresh(reason: .foreground)         — pull shared zone changes
                ├── ensureMembershipForAcceptedShare()   — create local caregiver membership
                └── refresh(reason: .localWrite)         — push the new membership
```

---

## Logging Added

`os.Logger` (subsystem: `com.adappt.BabyTracker`, category: `CloudKitSync`) and `print` statements were added throughout the sync pipeline to make the data flow observable. Key log points:

### Launch Sync
```
Launch sync starting
iCloud account status: available
iCloud user record ID: <hashed>
Checking shared database for changes (token: incremental/none — full fetch)
Shared database: N modified zone(s), N deleted zone(s)
Shared zone modified: child-<uuid>
Found N child(ren) in local store
Child '<name>' — zone: child-<uuid>, scope: private/shared
pullZoneSnapshot child-<uuid> (private/shared): N modified, N deleted — types: Child, Membership, ...
```

### Share Acceptance
```
[1/5] SceneDelegate fired — title: '<name>', zone: child-<uuid>
[2/5] Bridge.handle called — handler is ready / nil (queuing)
[3/5] ShareAcceptanceHandler task running
[4/5] Calling client.accept
[4/5] client.accept succeeded — running foreground refresh
[4/5] ensureMembership — existing memberships: [owner/active] / [none]
[4/5] ensureMembership — creating caregiver membership
[5/5] Share acceptance complete
```

Errors are logged explicitly in the catch paths so silent failures are visible.

---

## Bugs Found and Fixed

### 1. Share Acceptance Callback Never Fired

**Symptom:** No `[1/5]` log when opening the app via a share link. The full acceptance chain never ran.

**Root cause:** The app registered `UIApplicationDelegate.application(_:userDidAcceptCloudKitShareWith:)`. In all modern iOS apps (SwiftUI `App` protocol = scene-based), iOS routes share acceptance to `UIWindowSceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)` instead. The app delegate path is simply never called.

**Fix:** Added `CloudKitShareSceneDelegate` implementing `UIWindowSceneDelegate`, and registered it via `application(_:configurationForConnecting:options:)` in the app delegate.

**Files changed:**
- `Baby Tracker/App/CloudKitShareSceneDelegate.swift` — new file
- `Baby Tracker/App/CloudKitShareAppDelegate.swift` — added `configurationForConnecting`

---

### 2. Silent Error Swallowing in ShareAcceptanceHandler

**Symptom:** `[3/5]` logs appeared but nothing after — no `[4/5]` or error log.

**Root cause:** `ShareAcceptanceHandler.accept` used `try?` when calling `syncEngine.accept(metadata:)`, silently discarding any thrown error.

**Fix:** Replaced `try?` with a proper `do/catch` that logs the error at `.error` level and prints it.

**File changed:** `Packages/BabyTrackerSync/Sources/BabyTrackerSync/ShareAcceptanceHandler.swift`

---

### 3. Nil Handler Race on Cold Launch

**Symptom:** On cold launch via share link, the acceptance could be dropped entirely if the app delegate fired before `BabyTrackerApp.init()` had set the handler on the bridge.

**Fix:** `CloudKitShareAcceptanceBridge` now queues the metadata if `handler` is nil, and flushes it automatically via `didSet` when the handler is assigned.

**File changed:** `Baby Tracker/App/CloudKitShareAcceptanceBridge.swift`

---

### 4. `ensureMembershipForAcceptedShare` Fails with `missingOwner`

**Symptom:**
```
[4/5] ensureMembership — existing memberships: [none]
Sync engine accept FAILED: missingOwner
```

**Root cause (two parts):**

**Part A — Owner's CloudKit zone is incomplete.** The shared child's zone (`child-04B6BB72`) contained only 1 record: `Child`. No `Membership` and no `UserIdentity` were ever pushed by the owner's device. This means when the caregiver's device pulls the shared zone, it only gets the child record — no owner membership exists locally.

Why the zone is sparse: when `pushZoneSnapshot` first ran on the owner's device for this child, the membership records may not have existed yet (timing issue on first launch sync), or a previous push failed silently. The data gap is on the owner's side and requires the owner's device to trigger a re-sync (e.g. any edit to that child) to push the missing records.

**Part B — `saveMembership` validation is too strict for CloudKit scenarios.** `saveMembership` calls `MembershipValidator.validateOwnerMemberships` which requires at least one active owner membership to exist before any membership can be saved. For locally-owned children this is correct. But for a shared child being accepted by a caregiver, the owner's membership lives on a different account and may not have synced yet.

**Fix:** Added `saveCloudKitMembership(_ membership: Membership)` to `ChildProfileRepository` — identical to `saveMembership` but skips the owner validator. Used in `ensureMembershipForAcceptedShare` so the caregiver's membership can be saved regardless of whether the owner's data has arrived.

The shared `upsertMembership` private helper was extracted to avoid duplication.

**Files changed:**
- `Packages/BabyTrackerPersistence/Sources/BabyTrackerPersistence/ChildProfileRepository.swift` — added `saveCloudKitMembership` to protocol
- `Packages/BabyTrackerPersistence/Sources/BabyTrackerPersistence/SwiftDataChildProfileRepository.swift` — implemented it via shared `upsertMembership`
- `Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift` — use `saveCloudKitMembership` in `ensureMembershipForAcceptedShare`

---

### 5. Infinite Loop to Identity Onboarding After Share Acceptance

**Symptom:** After accepting a share, the app showed the caregiver naming screen. The user entered their name, reached the create-child screen, and after ~2 seconds was bounced back to naming. Repeated indefinitely.

**Root cause:** `refresh(selecting:)` in `AppModel` had a single catch block that routed **all thrown errors** to `route = .identityOnboarding`:

```swift
} catch {
    errorMessage = resolveErrorMessage(for: error)
    route = .identityOnboarding  // ← catches everything, including data errors
    liveActivityManager.synchronize(with: nil)
}
```

`makeProfile` throws `ChildProfileValidationError.missingOwner` when the selected child has no active owner membership in the local store (line 730-734). For "Robyn (S)" — where the owner's zone was sparse — there was no owner membership. So:

1. `loadActiveChildren` finds Robyn S (caregiver membership exists for local user) ✓
2. `makeProfile` is called → no owner → throws `missingOwner`
3. Catch → `route = .identityOnboarding`
4. User enters name → `refresh` → same path → loops

The catch-all-to-identity-onboarding was always wrong. `.identityOnboarding` should only be shown when there is genuinely no local user, which is already handled by the `guard let localUser` nil check earlier in `refresh`. Data errors from `makeProfile` should never reset the user's session.

**Fix:** The catch block now only redirects to `.identityOnboarding` if `localUser == nil`. If there is a local user and a data error occurs, the error message is shown but the route is preserved.

```swift
} catch {
    errorMessage = resolveErrorMessage(for: error)
    if localUser == nil {
        route = .identityOnboarding
        liveActivityManager.synchronize(with: nil)
    }
}
```

**File changed:** `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift`

---

## Known Remaining Issues

### Owner's Zone Missing Membership Records

The root data issue — the shared child's CloudKit zone only containing the Child record — is on the owner's device. Until the owner's device pushes their `Membership` and `UserIdentity` records to that zone, the shared child will display with no owner information.

**Effect after fixes:** The shared child is now accessible and the caregiver can log events. The owner field in the profile/sharing view will be absent until the owner's data syncs.

**How to resolve:**
- On the owner's device, any write to that child (e.g. adding an event, editing the name) will trigger `pushZoneSnapshot`, which will push all records including memberships and users
- Alternatively, investigate why `pushZoneSnapshot` didn't push membership records when the share was originally created — likely a first-launch timing race where the zone was pushed before the membership was created

### `makeProfile` Still Throws for Truly Ownerless Children

After the catch block fix, hitting a shared child with no owner membership shows an error message but stays on the current screen. The profile cannot be fully rendered without an owner. This will self-resolve once the owner's device syncs, but the UX could be improved (e.g. a "syncing..." placeholder state instead of an error banner).

---

## File Change Summary

| File | Change |
|---|---|
| `Baby Tracker/App/CloudKitShareSceneDelegate.swift` | New — handles `windowScene(_:userDidAcceptCloudKitShareWith:)` |
| `Baby Tracker/App/CloudKitShareAppDelegate.swift` | Added `configurationForConnecting` to register scene delegate; kept app delegate method as fallback |
| `Baby Tracker/App/CloudKitShareAcceptanceBridge.swift` | Added metadata queuing for nil-handler cold launch race; improved logging |
| `BabyTrackerSync/ShareAcceptanceHandler.swift` | Replaced `try?` with `do/catch`; added `os.Logger` and `print` logging |
| `BabyTrackerSync/CloudKitSyncEngine.swift` | Extensive logging throughout refresh, share acceptance, zone pulls, and membership saves; use `saveCloudKitMembership` in `ensureMembershipForAcceptedShare` |
| `BabyTrackerPersistence/ChildProfileRepository.swift` | Added `saveCloudKitMembership` to protocol |
| `BabyTrackerPersistence/SwiftDataChildProfileRepository.swift` | Implemented `saveCloudKitMembership` via shared `upsertMembership` helper |
| `BabyTrackerFeature/AppModel.swift` | Fixed catch block to only route to `.identityOnboarding` when `localUser == nil` |
