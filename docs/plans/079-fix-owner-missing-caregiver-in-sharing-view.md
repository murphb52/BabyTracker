# 079 — Fix: Owner doesn't see accepted caregiver in Sharing & Caregivers view

## Goal

After an owner invites a caregiver and the caregiver accepts the share, the owner's "Sharing & Caregivers" page must show the caregiver in the active caregivers section. Before this fix, the caregiver disappeared entirely from the owner's view after acceptance.

## Problem

When a caregiver accepts a CloudKit share, `ensureMembershipForAcceptedShare` creates a local `Membership` record with `role: .caregiver, status: .active`. The record was saved as `.pendingSync` via `saveCloudKitMembership`, but the code then immediately overrode that to `.upToDate`:

```swift
try syncStateRepository.updateSyncState(
    for: SyncRecordReference(recordType: .membership, ...),
    state: .upToDate,
    ...
)
```

The comment claimed this was "received from CloudKit, not a local write" — but the membership was created locally with a new UUID and was never in CloudKit. Marking it `.upToDate` prevented `refresh(reason: .localWrite)` (which runs immediately after) from uploading the membership to the shared CloudKit zone.

Since the caregiver's membership was never in CloudKit, the owner's device never received it:

1. The caregiver didn't appear in `activeCaregivers` (requires a membership with `role == .caregiver && status == .active` on the owner's device)
2. After acceptance, `cachePendingInvites` filtered the caregiver out of `pendingShareInvites` too (because `acceptanceStatus == .accepted` is excluded once they accept)

The caregiver disappeared from the owner's view entirely.

## Fix

Removed the premature `.upToDate` marking block (10 lines) from `ensureMembershipForAcceptedShare` in `CloudKitSyncEngine.swift`. The membership now remains `.pendingSync`, so the subsequent `refresh(reason: .localWrite)` uploads it to the shared CloudKit zone. The owner's private zone subscription receives the change and pulls the caregiver's membership, making them visible in `activeCaregivers`.

## Files Changed

- `Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift`

- [x] Complete
