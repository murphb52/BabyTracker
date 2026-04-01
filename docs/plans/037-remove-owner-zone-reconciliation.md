## Goal

Remove `shouldForceOwnerSharedZoneReconciliation` from `CloudKitSyncEngine`. The function forces a full zone pull on every `launch`, `foreground`, and `remoteNotification` sync for shared zones. It was added in plan 022 when change tokens were unreliable for caregiver writes. Remote notifications and robust incremental sync now cover those gaps.

Full syncs are still preserved where genuinely needed:
- Share acceptance — first fetch of a newly shared zone.
- Manual refresh button — user escape hatch.
- Token expiry — automatic CloudKit fallback.

## Changes

**`Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift`**

1. Delete `shouldForceOwnerSharedZoneReconciliation(for:context:)`.
2. In `pullKnownChildZones`: remove the `skipReconciliation` parameter and the reconciliation `else if` branch. The function becomes: force full fetch if `forceFullFetch`, else incremental.
3. In `pushPendingChanges` (the no-arg overload): remove the `skipReconciliation` parameter and the reconciliation guard.
4. In `refresh(reason:)`: remove the `skipReconciliation: true` arguments added in #106.

**`Baby TrackerTests/CloudKitSyncEngineTests.swift`**

Update `localWriteRefreshPullsRemoteCaregiverEventsFromPrivateZone`:
- The test currently passes because no anchor is stored, causing a full initial pull. That is still correct behaviour — it verifies caregiver events surface on the first sync of a zone.
- Remove the assertion that `tokenWasNil == true` if it was added to verify reconciliation specifically. Keep the assertion that the caregiver event is found locally after the sync.

## Verification

1. Build succeeds, all tests pass.
2. On a device with a shared child zone, open the app — logs should show incremental zone pulls, not full snapshot pulls, on launch and foreground.
3. Log a new event as a caregiver — the owner's device should pick it up via the remote notification path.
4. The manual "Force full sync" button still triggers a full pull.
5. Accepting a share still triggers a full pull of the new zone.

- [ ] Complete
