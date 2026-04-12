# 080 — Fix: Owner still sees caregiver as active after they leave

## Goal

When a caregiver leaves a shared child profile, the owner's "Sharing & Caregivers" page should move them to the "Past Access" section. Before this fix, the caregiver's membership record remained `.active` on the owner's device indefinitely after departure.

## Problem

`leaveChildShare` in `AppModel.swift` called `leaveShare` (which deletes the shared zone from CloudKit) and then `purgeChildData` (which wipes the caregiver's local data). Neither step updated the caregiver's membership record to `.removed` or pushed that update to CloudKit.

The membership record in the owner's private CloudKit zone kept `status: .active`. On the owner's next sync, they would pull the unchanged record and continue to see the caregiver listed as an active caregiver.

The owner had no indication the caregiver had left until they manually removed them using the "Remove" button.

## Fix

Before deleting the zone and purging local data, `leaveChildShare` now:

1. Transitions the membership to `.removed` via `membership.removed()`
2. Saves it locally via `membershipRepository.saveMembership` (marks it `.pendingSync`)
3. Pushes it to CloudKit via `syncEngine.refreshAfterLocalWrite()`

The push happens while the shared zone still exists, so the write succeeds. The owner's device receives the `.removed` record on their next sync and moves the caregiver to "Past Access".

## Files Changed

- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift`

- [x] Complete
