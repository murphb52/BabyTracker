# CloudKit, SwiftData, and Sharing Storage Review

Date: 2026-03-30

## Goal

Review the app's data storage and sync stack, compare it to current Apple guidance, and identify the changes most worth experimenting with for the symptom:

- after sharing, some events sync between two apps
- some events do not sync
- behavior feels spotty and inconsistent

## Executive Summary

The app is not using SwiftData's built-in CloudKit syncing. SwiftData is acting as a local cache, and CloudKit sync is implemented manually in `BabyTrackerSync`.

That architecture is valid, but the current implementation differs from Apple guidance in a few important ways that can plausibly explain "some events sync, some do not":

1. The app only handles share acceptance through `windowScene(_:userDidAcceptCloudKitShareWith:)` and the deprecated app-delegate path. Apple documents an additional cold-launch path through `UIScene.ConnectionOptions.cloudKitShareMetadata`, and that path is not implemented here.
2. The app uses `CKDatabaseSubscription` for the private database, while Apple recommends `CKRecordZoneSubscription` for custom private zones and reserves `CKDatabaseSubscription` for cases like the shared database where zones are not known ahead of time.
3. The app re-sends the entire child zone on each local write instead of sending only the pending records. That is the biggest architectural divergence from Apple's modern guidance and is the change most likely to create scale-related "spotty" behavior.
4. The app does not persist CloudKit record metadata or change tags locally, and it saves with `.changedKeys` using freshly synthesized `CKRecord` objects. Per Apple docs, that means it is not using the record metadata that CloudKit expects for robust local/cloud reconciliation.
5. The app uses hierarchical sharing correctly now, but because the whole child zone is conceptually shareable, a zone-wide share is worth testing. That would remove one source of fragility.

My recommendation is to try changes in this order:

1. Add cold-launch share acceptance from `UIScene.ConnectionOptions.cloudKitShareMetadata`.
2. Change private-database subscriptions from database subscriptions to per-zone subscriptions.
3. Replace full-zone pushes with incremental pushes of only pending records.
4. Persist system fields and change tags locally, then move conflictable saves to `ifServerRecordUnchanged`.
5. Prototype zone-wide sharing with `CKShare(recordZoneID:)` for one child zone.

## Architecture Reviewed

### Local storage

- [BabyTrackerModelStore.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerPersistence/Sources/BabyTrackerPersistence/BabyTrackerModelStore.swift#L4)
- `ModelContainer` is configured only with a schema and `isStoredInMemoryOnly`.
- There is no SwiftData CloudKit configuration in the model store.

### Manual CloudKit sync layer

- [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift)
- [LiveCloudKitClient.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/LiveCloudKitClient.swift)
- [CloudKitRecordMapper.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitRecordMapper.swift)

### Share acceptance lifecycle

- [CloudKitShareAppDelegate.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/CloudKitShareAppDelegate.swift)
- [CloudKitShareSceneDelegate.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/CloudKitShareSceneDelegate.swift)
- [CloudKitShareAcceptanceBridge.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/CloudKitShareAcceptanceBridge.swift)

### Tests reviewed

- [CloudKitSyncEngineTests.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby TrackerTests/CloudKitSyncEngineTests.swift)
- [CloudKitRecordMapperTests.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby TrackerTests/CloudKitRecordMapperTests.swift)

## What Matches Apple Guidance

### 1. SwiftData is being used as a local cache, not as the sync engine

This is consistent with CloudKit's model: your app owns the local model and is responsible for converting between local objects and CloudKit records.

The code reflects that:

- [BabyTrackerModelStore.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerPersistence/Sources/BabyTrackerPersistence/BabyTrackerModelStore.swift#L7)
- [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L293)

This means SwiftData itself is probably not the direct source of the spotty behavior. The higher-risk area is the custom CloudKit engine.

### 2. The app uses change tokens to fetch incremental changes

This aligns with Apple's "Remote Records" guidance.

The code does this in both places Apple expects:

- shared database change tokens: [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L383)
- zone change tokens: [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L721)

### 3. The app correctly fetches from the shared database after accepting a share

This is good and doc-aligned.

After `client.accept([metadata])`, the app forces a full pull of the accepted shared zone:

- [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L260)
- [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L704)

That is directionally correct per Apple's guidance that after acceptance you should begin fetching the shared records.

### 4. The hierarchical sharing fix is correct

The current mapper attaches memberships, user identities, and events to the child record with `record.parent`.

That matches Apple's documented hierarchical sharing model:

- memberships: [CloudKitRecordMapper.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitRecordMapper.swift#L34)
- users: [CloudKitRecordMapper.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitRecordMapper.swift#L57)
- events: [CloudKitRecordMapper.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitRecordMapper.swift#L152)

This was previously a known bug in the repo, and the current code now matches Apple's sharing model.

### 5. Remote notifications are wired up and foreground refresh exists

The app registers for remote notifications, creates subscriptions, handles CloudKit pushes, and also refreshes in foreground:

- app delegate push registration: [CloudKitShareAppDelegate.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/CloudKitShareAppDelegate.swift#L23)
- subscription creation: [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L350)
- remote notification handler bridge: [BabyTrackerApp.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/BabyTrackerApp.swift#L11)

That is all good. It also means if syncing is still spotty, the remaining issues are more likely to be subscription type choice, share lifecycle holes, or outbound save strategy.

## Where The App Differs From Apple Guidance

### 1. Cold-launch share acceptance path is missing

Apple documents that:

- `windowScene(_:userDidAcceptCloudKitShareWith:)` is only called when the app is already running and already has a scene.
- if the app is not running, the system passes the share metadata in `UIScene.ConnectionOptions` when creating the first scene.

The app currently handles:

- running app scene callback: [CloudKitShareSceneDelegate.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/CloudKitShareSceneDelegate.swift#L12)
- deprecated app delegate fallback: [CloudKitShareAppDelegate.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Baby Tracker/App/CloudKitShareAppDelegate.swift#L75)

What it does not handle:

- reading `connectionOptions.cloudKitShareMetadata` during first scene creation

Why this matters:

- if a user accepts a share while the app is not already running, the acceptance flow may be incomplete or timing-dependent
- that can produce "share accepted, some records show up later or inconsistently" behavior

This is the cleanest doc mismatch in the repo.

### 2. Private custom zones use `CKDatabaseSubscription`, not `CKRecordZoneSubscription`

Apple's "Remote Records" guidance says:

- use a database subscription when you don't know what zones exist, such as the shared database
- use a record zone subscription for a custom record zone in the user's private database

The app creates database subscriptions for both `.private` and `.shared`:

- [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L355)

Why this matters:

- the shared database subscription is aligned with Apple guidance
- the private database subscription is broader than needed and not the recommended type for known custom zones
- if remote delivery is part of the perceived spotty behavior, this is a strong experiment candidate

I would not call this the most likely root cause by itself, but it is a real doc mismatch.

### 3. The app pushes the entire child zone on every local write

This is the biggest divergence from Apple's modern sync guidance.

When there are pending records, the app does not send only those records. Instead it:

- loads the child
- loads all memberships
- loads all related users
- loads the full event timeline, including deleted events
- rebuilds a full array of CKRecords
- saves the whole set

Relevant code:

- local writes trigger refresh: [AppModel.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift#L723)
- pending refresh calls push path: [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L514)
- full-zone save happens here: [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L578)

Why this matters:

- it scales poorly as event counts grow
- every single edit re-sends unrelated events
- large batches are exactly the kind of thing that turns sync from "works in a tiny test case" into "spotty in real use"
- Apple's CKSyncEngine guidance is explicitly batch-oriented and based on sending the next pending changes, not rebuilding and saving an entire zone every time

This is the first storage/sync behavior I would change if the goal is to reduce intermittent missing events.

### 4. CloudKit record metadata and change tags are not persisted locally

Apple's docs are explicit that if you store records locally, you should store the record metadata, including record ID and change tag.

This repo does not persist system fields or change tags for child, membership, user, or event records.

Evidence:

- the local models store sync state, anchors, and CloudKit zone context, but not record metadata/system fields
- [StoredChild.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerPersistence/Sources/BabyTrackerPersistence/Models/StoredChild.swift#L7)
- `rg` across the codebase found no use of `encodeSystemFields(with:)`, `recordChangeTag`, or stored system fields

Why this matters:

- the sync layer keeps record IDs stable, but it does not preserve server metadata
- that removes a standard tool Apple expects you to use for robust local/cloud reconciliation
- it also limits your ability to use stricter conflict detection or diagnose why one record saved while another did not

### 5. The app uses `.changedKeys` with freshly synthesized `CKRecord` objects

The app saves with `.changedKeys` here:

- [CloudKitSyncEngine.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift#L636)

Those records are not fetched-and-mutated server records. They are newly constructed local records from the mapper:

- [CloudKitRecordMapper.swift](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitRecordMapper.swift#L5)

Per Apple docs:

- `.changedKeys` does not compare record change tags
- a fresh record's changed keys are the keys changed since download or save

Inference:

- because these records are synthesized from scratch, `.changedKeys` is effectively acting as a blind field overwrite path, not a change-tag-validated merge path
- the repo partly compensates for this with `LastWriteWinsResolver`, but that is app-level logic, not server-level conflict control

I am calling this an inference from the Apple docs plus the code shape, but it is a strong one.

### 6. The app still uses hierarchical sharing instead of a zone-wide share

This is not wrong.

The current implementation uses:

- one custom zone per child
- one root child record
- child descendants connected with `parent`
- `CKShare(rootRecord:childRecord, shareID:...)`

That matches Apple's hierarchical share model.

But because the entire zone conceptually belongs to the child anyway, Apple now provides a simpler option for "share all records in this zone":

- `CKShare(recordZoneID:)`

Why this matters:

- hierarchical sharing is more fragile because every shared record has to stay in the correct parent hierarchy
- zone-wide sharing removes that class of bug entirely
- given your domain model, a child-as-zone maps naturally to zone-wide sharing

This is an experiment worth trying even though the current code is technically valid.

## Most Likely Causes Of The "Spotty Events" Symptom

Ordered from most likely to least likely.

### 1. Full-zone re-upload on every local change

Why I think this is the highest-probability issue:

- the push path re-sends all events, not just changed ones
- that creates more network work, more server work, and more opportunity for intermittent failure as the child history grows
- the symptom you reported is about events specifically, and events are the largest fan-out in the zone

### 2. Missing cold-launch share acceptance path

Why this is plausible:

- it is a documented Apple lifecycle path that is currently missing
- share acceptance problems often present as "some data eventually appears" rather than a clean total failure

### 3. Private-database subscription type mismatch

Why this is plausible:

- the app uses a database subscription where Apple recommends a zone subscription
- if push delivery or change classification is part of the inconsistency, this is a reasonable lever to test

### 4. No stored system fields / change tags

Why this is plausible:

- it reduces the sync engine's ability to reason about server state precisely
- it pushes more responsibility onto custom merge logic

### 5. Hierarchical share fragility

Why this is less likely than the above today:

- the parent-reference fix is present and tested
- `prepareShare()` pushes the zone before creating the share

Still, zone-wide sharing could simplify the entire system.

## Recommended Experiments

### Experiment 1: Add cold-launch share acceptance

Change:

- read `connectionOptions.cloudKitShareMetadata` when the first scene is created
- forward that metadata through `CloudKitShareAcceptanceBridge`

Expected result:

- share acceptance becomes deterministic whether the app was already running or not

Success signal:

- accepting a share from a cold start always produces a local child and events immediately after acceptance

### Experiment 2: Use `CKRecordZoneSubscription` for private child zones

Change:

- keep `CKDatabaseSubscription` for `.shared`
- create a `CKRecordZoneSubscription` for each private child zone after zone creation

Expected result:

- more doc-aligned push behavior for owner-side private zones

Success signal:

- owner and participant devices receive remote-driven refreshes more consistently without needing manual foreground refresh

### Experiment 3: Replace full-zone pushes with incremental pushes

Change:

- derive outbound CKRecords only from the pending `SyncRecordReference`s
- save only those pending records
- batch large sends instead of building one full snapshot

Expected result:

- much lower sync volume
- fewer opportunities for missed or delayed event propagation
- better behavior as event history grows

Success signal:

- the number of records sent per edit becomes small and predictable
- spotty event propagation improves immediately in real usage

### Experiment 4: Persist CloudKit system fields and change tags

Change:

- add per-entity storage for encoded CloudKit system fields
- on fetch, update stored metadata
- on save, reconstruct CKRecords from stored system fields when available

Expected result:

- more precise server reconciliation
- better conflict handling
- easier debugging

Success signal:

- clearer conflict errors
- less need for blind overwrite behavior

### Experiment 5: Switch one child flow to zone-wide sharing

Change:

- prototype `CKShare(recordZoneID:)` for a test branch
- stop relying on `parent` hierarchy for share membership

Expected result:

- eliminate an entire class of "record is in the zone but not actually in the share" failures

Success signal:

- all records in the zone consistently appear to participants without relying on parent-reference correctness

## Suggested Implementation Order

1. Add cold-launch share acceptance from `UIScene.ConnectionOptions`.
2. Change private subscriptions to `CKRecordZoneSubscription`.
3. Instrument outbound pushes with record counts and batch sizes.
4. Refactor outbound sync to send only pending records.
5. Add stored system fields and change tags.
6. If needed, prototype zone-wide sharing.

## Notes On Current Tests

Focused CloudKit sync tests pass locally:

- `CloudKitSyncEngineTests`
- `CloudKitRecordMapperTests`

Command used:

```bash
xcodebuild test -scheme "Baby Tracker" -testPlan UnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:"Baby TrackerTests/CloudKitSyncEngineTests" -only-testing:"Baby TrackerTests/CloudKitRecordMapperTests"
```

That is useful, but it also means the current test suite is not exercising the most likely real-world failure modes:

- cold-launch share acceptance via scene connection options
- large child histories
- incremental event-only sync under real network timing
- record metadata / change-tag reconciliation

## Apple Sources

- Apple, `windowScene(_:userDidAcceptCloudKitShareWith:)`: says this method is only called when the app is already running, and cold-launch share metadata arrives in `UIScene.ConnectionOptions`.  
  https://developer.apple.com/documentation/uikit/uiwindowscenedelegate/windowscene%28_%3Auserdidacceptcloudkitsharewith%3A%29

- Apple, `application(_:userDidAcceptCloudKitShareWith:)`: deprecated for scene-based apps, and explicitly points scene-based apps to the window-scene delegate path.  
  https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application%28_%3Auserdidacceptcloudkitsharewith%3A%29

- Apple, `Remote Records`: use subscriptions and change tokens; use database subscriptions when you do not know zones, such as the shared database; use record-zone subscriptions for custom private zones; attach record metadata including change tags to local models.  
  https://developer.apple.com/documentation/cloudkit/remote-records

- Apple, QA1917: CloudKit subscriptions are per-user, depend on APNs delivery, and database subscriptions track custom-zone changes in private/shared databases.  
  https://developer.apple.com/library/archive/qa/qa1917/_index.html

- Apple, `CKRecord`: if you store records locally, store system fields because the metadata includes the record ID and change tag you need later to sync with CloudKit.  
  https://developer.apple.com/documentation/cloudkit/ckrecord

- Apple, `CKModifyRecordsOperation.RecordSavePolicy.changedKeys`: `.changedKeys` does not compare change tags; Apple recommends `ifServerRecordUnchanged` when you need change-tag validation.  
  https://developer.apple.com/documentation/cloudkit/ckmodifyrecordsoperation/recordsavepolicy/changedkeys

- Apple, Tech Talk `Get the most out of CloudKit Sharing`: demonstrates hierarchical sharing and also shows sharing an entire record zone with `CKShare(recordZoneID:)`.  
  https://developer.apple.com/videos/play/tech-talks/10874

- Apple, WWDC21 `What's new in CloudKit`: explains that parent references create the hierarchy that CloudKit shares from a root record, and also introduces zone-wide sharing for bucket-style zones.  
  https://developer.apple.com/videos/play/wwdc2021/10086

- Apple, WWDC23 `Sync to iCloud with CKSyncEngine`: emphasizes pending-change batching, push handling, and reducing custom sync complexity.  
  https://developer.apple.com/videos/play/wwdc2023/10188
