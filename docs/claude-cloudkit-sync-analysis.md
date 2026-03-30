# CloudKit Sync Analysis: Current Implementation vs Apple Docs

This document maps what's built against Apple's recommended patterns for CloudKit sharing, identifies specific divergences, and lists concrete experiments to try for resolving spotty sync.

---

## Architecture Overview

The app uses a **custom CloudKit sync engine** rather than Apple's built-in `NSPersistentCloudKitContainer` integration. SwiftData manages local persistence; `CloudKitSyncEngine` orchestrates all CloudKit reads and writes independently. This is a valid and deliberate choice given the zone-per-child sharing model — but it means every CloudKit behaviour that `NSPersistentCloudKitContainer` handles automatically must be implemented and maintained manually.

**Zone topology:**

- One CloudKit container: `iCloud.com.adappt.BabyTracker`
- One zone per child: `child-{UUID}` in the **private** database (owner)
- Accepted shares: same zones accessed via the **shared** database (caregiver)
- All records in a zone are descendants of the `Child` record via `record.parent`

---

## What's Built Correctly

These areas match Apple's recommended patterns.

### 1. `record.parent` hierarchy for sharing

Every event, membership, and user record sets `record.parent` pointing to the child record. This is required for CloudKit sharing — CloudKit only shares the root record and its descendants.

```
CloudKitRecordMapper.swift:51-54, 74, 164-166, 189, 207, 225
```

Without this, a share only includes the `Child` record itself; events and memberships are invisible to the caregiver. This was fixed; the hierarchy is now correct.

### 2. Zone change tokens (incremental fetch)

`pullZoneSnapshot` stores a `CKServerChangeToken` per zone and passes it on the next fetch. When nil, a full fetch is performed. This matches the pattern Apple recommends with `CKFetchRecordZoneChangesOperation`.

```
CloudKitSyncEngine.swift:721-772
LiveCloudKitClient.swift:121-160
```

The `moreComing` pagination loop in `recordZoneChanges` is also handled correctly — it keeps fetching until `moreComing == false`.

### 3. Database change tokens (shared database detection)

`pullSharedDatabaseChanges` stores a database-level change token and uses it to detect new/deleted shared zones. This is Apple's recommended approach for discovering which zones changed in the shared database.

```
CloudKitSyncEngine.swift:383-431
```

### 4. `CKDatabaseSubscription` with silent push

Both `.private` and `.shared` database subscriptions are created with `shouldSendContentAvailable = true`. This is the correct CloudKit subscription type for triggering silent background refresh.

```
CloudKitSyncEngine.swift:350-371
```

### 5. Save policy `.changedKeys` on push

`modifyRecords` uses `.changedKeys`, which is the correct policy for shared zones. It means CloudKit only updates fields that changed rather than replacing the full server record. This prevents silent overwrites in concurrent-edit scenarios.

```
CloudKitSyncEngine.swift:640
```

### 6. Remote notification wiring

The app delegate registers for remote notifications at launch, and `didReceiveRemoteNotification:fetchCompletionHandler:` is correctly routed through `CloudKitRemoteNotificationBridge` to the sync engine.

```
CloudKitShareAppDelegate.swift:23-73
BabyTrackerApp.swift (CloudKitRemoteNotificationBridge.shared.handler assignment)
```

### 7. Share acceptance force-pull

After `client.accept()` resolves, the engine immediately does a full zone pull before returning. This ensures the caregiver's device has all the shared data before the UI shows it.

```
CloudKitSyncEngine.swift:704-719
```

---

## Gaps vs Apple's Recommended Patterns

These are the areas where the implementation diverges from what Apple documents and recommends.

---

### Gap 1: `moreComing` is NOT handled for database changes

**Severity: HIGH — can silently miss shared zone changes**

`databaseChanges()` in `LiveCloudKitClient` extracts `moreComing` from the response and includes it in `CloudKitDatabaseChangeSet`, but `pullSharedDatabaseChanges` in the sync engine makes exactly one call and does not loop.

```swift
// LiveCloudKitClient.swift — moreComing IS returned
return CloudKitDatabaseChangeSet(
    modifiedZoneIDs: changes.modifications.map(\.zoneID),
    deletedZoneIDs: changes.deletions.map(\.zoneID),
    tokenData: try archive(token: changes.changeToken),
    moreComing: changes.moreComing  // ← extracted but never acted on
)

// CloudKitSyncEngine.swift:383-431 — moreComing is NEVER checked
let changes = try await client.databaseChanges(in: .shared, since: anchor?.tokenData)
// … processes the results, saves token, returns
// No loop. If moreComing == true, the next batch of zone changes is silently dropped.
```

**Apple's pattern** (from `CKFetchDatabaseChangesOperation` docs): fetch, process results, check `moreComing`, repeat with the new token until `moreComing == false`.

**Impact on spotty sync:** If multiple shared zones changed between syncs (e.g., after both the owner and caregiver added events, then the caregiver opens the app), CloudKit may return `moreComing = true`. Only the first page of zone IDs is processed; remaining zones are skipped until the next full refresh cycle.

**Experiment:** Add logging for `changes.moreComing` in `pullSharedDatabaseChanges`. If you see it is `true` in practice, add the pagination loop.

---

### Gap 2: Full zone snapshot push (not incremental)

**Severity: MEDIUM — expensive, and the LWW guard has edge cases**

`pushZoneSnapshot` rebuilds the entire zone on every push: child record + all users + all memberships + all events (including deleted ones). It then does a pre-push fetch of all existing remote records for LWW comparison before calling `modifyRecords`.

Apple's pattern for sync is to push only changed records — the records the local engine knows are dirty (pending). The sync state tracking already marks records as `.pending`; `pushPendingChanges` collects them. But then it calls `pushZoneSnapshot` which ignores that and pushes everything anyway.

**Why this is risky for shared zones:**

1. The pre-push fetch + LWW only protects *events*. Child, membership, and user records skip the LWW check and are always included in `filteredSaves`. If a caregiver updated a membership and the owner pushes before pulling that change, the owner's version wins even if it's older.

2. Each full push is an atomic `modifyRecords` call. If any one record fails (e.g., `serverRecordChanged`), the entire operation fails and nothing is marked `upToDate`. The next sync retries everything.

3. After a successful push, **all records** in the zone are marked `upToDate` regardless of whether they were individually verified. If `modifyRecords` partially applied (CloudKit does not guarantee all-or-nothing for `.changedKeys`), local sync state can desync from CloudKit state.

**Apple's recommended pattern:** build a `CKModifyRecordsOperation` with only the changed records, use `.ifServerRecordUnchanged` for new records and `.changedKeys` for updates, handle per-record errors in `perRecordSaveBlock`, and retry `serverRecordChanged` errors after merging with the server version.

**Experiment:** Add LWW protection for `Child` and `Membership` records in `pushZoneSnapshot`, not just events. This is a lower-risk experiment than rewriting the push strategy.

---

### Gap 3: No `CKRecordZoneSubscription` per child zone

**Severity: MEDIUM — forces full database scans on every notification**

Only `CKDatabaseSubscription` is created. When CloudKit sends a silent push for a change in any zone, the app's handler runs `pullSharedDatabaseChanges` + `pullKnownChildZones` for every zone it knows about.

Apple's docs distinguish two subscription types:
- `CKDatabaseSubscription` — fires when any zone in the database changes; used to discover new/deleted zones
- `CKRecordZoneSubscription` — fires for a specific zone; used to trigger zone-specific fetches

With only database subscriptions, a push for zone A triggers a pull of zones A, B, C, D, and E. As the number of children grows this becomes increasingly expensive. More importantly, it means a single remote notification can time out the background fetch budget before all zones are processed, causing changes in later zones to be missed until the next foreground sync.

**Apple's pattern** (from WWDC "CloudKit Best Practices"): use `CKDatabaseSubscription` only for discovering new zones; create a `CKRecordZoneSubscription` for each zone you want to track, and use those subscriptions to drive targeted zone pulls.

**Experiment (low risk):** After creating or accepting a zone, also register a `CKRecordZoneSubscription` for it. In the remote notification handler, parse which zone triggered the push (available in `CKQueryNotification` and `CKRecordZoneNotification`) and pull only that zone. This significantly reduces what happens per notification.

---

### Gap 4: CKError handling is not per-record

**Severity: MEDIUM — errors silently abort the entire zone sync**

The `refresh()` function wraps the entire sync cycle in a single `do/catch`. Any error anywhere (network, CloudKit quota, `serverRecordChanged`, zone token invalidated) sets the entire sync state to `.failed` and returns.

There is no per-record error handling, no retry for transient errors, and no distinction between recoverable errors (`networkUnavailable`, `serviceUnavailable`, `requestRateLimited`) and permanent errors (`unknownItem`, `invalidArguments`).

Apple's `CKModifyRecordsOperation` provides `perRecordSaveBlock` and `perRecordDeleteBlock` callbacks that receive individual record errors. Retrying only the failed records — rather than the entire zone — is the recommended pattern.

**CloudKit errors that need special handling and are not currently handled:**

| Error | What it means | Apple's recommended response |
|---|---|---|
| `serverRecordChanged` | Remote has a newer version | Merge local + server, retry |
| `zoneNotFound` | Zone was deleted externally | Delete local child data, recreate zone |
| `userDeletedZone` | Owner deleted their zone | Purge local child from caregiver device |
| `changeTokenExpired` | Zone token is stale | Nil the token, do a full fetch |
| `requestRateLimited` | CloudKit throttling | Wait `retryAfterSeconds`, retry |

**Experiment:** Wrap `modifyRecords` in a retry loop that handles `changeTokenExpired` (reset token, re-fetch) and `requestRateLimited` (sleep `retryAfterSeconds`). These two cover the most common transient failure modes.

---

### Gap 5: Push marks all records `upToDate` before confirming individual success

**Severity: MEDIUM — sync state can lie after partial failures**

After a successful `modifyRecords` call, `pushZoneSnapshot` iterates all events, memberships, users, and the child record and marks each one `upToDate`. This happens after the single `modifyRecords` call returns without throwing.

Two problems:

1. `modifyRecords` with `.changedKeys` does not guarantee that every record was written atomically. CloudKit can return success even if some records had no-op updates (unchanged fields). The engine treats "no error thrown" as "everything was saved."

2. If the push succeeds but a subsequent pull immediately returns a conflicting version of a record (because CloudKit propagated a caregiver write between the push fetch and the push), the local state is marked `upToDate` but the remote has a different version. The next incremental pull will not see this as a conflict — it will apply the remote version over the "upToDate" local record.

**Experiment:** After `modifyRecords`, do a verification fetch of the first few pushed records and confirm their `modificationDate` matches expectations. This is not a production fix but will confirm whether silent divergence is occurring.

---

### Gap 6: No `changeTokenExpired` recovery for zone tokens

**Severity: MEDIUM — once a zone token expires, incremental sync stops working**

Zone change tokens can expire if a zone was deleted and recreated, or if CloudKit purges old token history (this can happen after extended inactivity). When a stale token is sent, CloudKit returns `CKError.changeTokenExpired`.

The current engine does not handle this error. If it occurs during `pullZoneSnapshot`, the error propagates up, `refresh()` returns `.failed`, and the zone will fail on every subsequent incremental sync.

Apple's recommended recovery: catch `changeTokenExpired`, discard the stored anchor token (set it to `nil`), and retry the zone pull with a full fetch.

**Experiment:** Add a catch for `CKError.changeTokenExpired` in `pullZoneSnapshot` that clears the anchor and retries with `forceFullFetch: true`. This is a safe, contained fix.

---

### Gap 7: Owner-side reconciliation uses a network round-trip per zone

**Severity: LOW (correctness) / MEDIUM (performance)**

`shouldForceOwnerSharedZoneReconciliation` makes a live CloudKit fetch of the share record on every sync cycle to verify the share still exists. This means:

- Every sync for every shared child zone costs one extra `records(for:)` call
- If the device is offline or CloudKit is slow, this check fails and the sync engine skips reconciliation — which may be wrong depending on the failure mode
- It queries CloudKit to answer "does this zone have a share?" when this information is already stored locally in `cloudKitShareRecordName`

**Apple's pattern:** trust local state for existence checks unless you have a specific reason to verify. The share record name is already stored in `StoredChild`. Use it directly; only do a live fetch when local state is ambiguous (first launch, after a deletion event, after share acceptance).

**Experiment (low risk):** Trust the locally-stored `shareRecordName` for the `shouldForceOwnerSharedZoneReconciliation` check. Only do the live CloudKit fetch if local state indicates the share was recently created or accepted. This removes one network call per shared zone per sync.

---

### Gap 8: Push conflict check only covers events, not child/membership/user records

**Severity: MEDIUM — caregiver membership changes can be silently overwritten**

In `pushZoneSnapshot`, the LWW conflict check applies only to records that can be decoded as an `AnyEvent`. Child records, `UserIdentity` records, and `Membership` records all bypass the check and go directly into `filteredSaves`.

If a caregiver's name is updated on their device (updating `UserIdentity`) and the owner's device pushes before pulling that change, the owner's stale `UserIdentity` record will overwrite the caregiver's update.

**Apple's pattern with `.changedKeys`:** Only send the fields you know changed. The app sends full records every time, relying on CloudKit's `.changedKeys` policy to merge. This is correct at the field level, but it doesn't account for whole-record replacement if the remote changed a field the local record doesn't know about.

**Experiment:** For `Child`, `Membership`, and `UserIdentity` records in `pushZoneSnapshot`, compare local `updatedAt` against the remote record's `modificationDate`. If remote is newer, skip saving that record locally and don't include it in the push. This mirrors the LWW logic already applied to events.

---

## Summary Table

| Gap | Severity | Likely contributes to spotty sync? | Recommended experiment |
|---|---|---|---|
| `moreComing` not looped for database changes | HIGH | Yes — zones can be silently skipped | Add pagination loop in `pullSharedDatabaseChanges` |
| Full zone snapshot push | MEDIUM | Yes — LWW only covers events | Add LWW check for Child/Membership/User records |
| No zone-level subscriptions | MEDIUM | Yes — background fetches miss changes | Add `CKRecordZoneSubscription` per zone |
| No per-record error handling | MEDIUM | Yes — one error aborts entire zone | Add retry for `changeTokenExpired`, `requestRateLimited` |
| Sync state marked before record-level verification | MEDIUM | Possibly — state lies after partial failures | Add post-push verification (diagnostic first) |
| `changeTokenExpired` not handled | MEDIUM | Yes — broken zone tokens cause permanent failure | Catch and recover with full fetch |
| Reconciliation uses live network check | LOW | No — correctness is fine, just slow | Trust local `shareRecordName` instead |
| No LWW for non-event records | MEDIUM | Possibly — membership/user overwrites | Extend LWW to all record types in push |

---

## Recommended Experiment Order

Start with the highest-confidence, lowest-risk fixes:

**1. Fix `moreComing` pagination in `pullSharedDatabaseChanges`**

This is a clear bug with documented Apple guidance. Add a loop that keeps calling `databaseChanges` until `moreComing == false`. Risk: very low. Payoff: high if you have multiple shared zones and active usage.

**2. Add `changeTokenExpired` recovery in `pullZoneSnapshot`**

Catch `CKError.changeTokenExpired`, clear the zone anchor, retry with `forceFullFetch: true`. This is a contained, safe fix that prevents permanent zone sync failure.

**3. Add LWW check for Child/Membership/User records in `pushZoneSnapshot`**

Extend the existing event LWW logic to all record types. Compare local `updatedAt` against `CKRecord.modificationDate` and skip records where remote is newer. Low risk; mirrors existing pattern.

**4. Add diagnostic logging for `moreComing` and per-zone push/pull counts**

Before adding zone subscriptions (Gap 3), add logs for:
- `changes.moreComing` in `pullSharedDatabaseChanges`
- Number of records sent per zone push
- Which records were skipped by LWW

This creates an evidence base to confirm which gaps are actually causing the observed spotty sync before investing in larger changes.

**5. Add `CKRecordZoneSubscription` per child zone**

After the above fixes are in place, evaluate whether sync speed is still an issue. If notifications are still slow or missed, add per-zone subscriptions and update the notification handler to do targeted zone pulls instead of full database scans.

---

## Reference: Key Files

| File | Role |
|---|---|
| `BabyTrackerSync/CloudKitSyncEngine.swift` | Main sync orchestration — pull/push/subscribe |
| `BabyTrackerSync/LiveCloudKitClient.swift` | CKDatabase API wrappers |
| `BabyTrackerSync/CloudKitRecordMapper.swift` | Record creation and `record.parent` assignment |
| `BabyTrackerSync/CloudKitConfiguration.swift` | Container ID and record type constants |
| `BabyTrackerPersistence/BabyTrackerModelStore.swift` | SwiftData ModelContainer setup |
| `BabyTrackerPersistence/SwiftDataSyncStateRepository.swift` | Anchor token and pending record tracking |
| `Baby Tracker/App/CloudKitShareAppDelegate.swift` | Remote notification registration and routing |
| `docs/CloudKit_Sync_Engine_Guide.md` | Architecture guide |
| `docs/CloudKit_Sync_Architecture_and_Debugging.md` | Debugging history and known fixes |
