# 047 Improve Syncing Indicator

## Goal
Implement GitHub issue [#98](https://github.com/murphb52/BabyTracker/issues/98) by making the app-wide sync indicator smaller, less intrusive, anchored to the top-right, and animated as a compact status affordance.

## Scope
1. Keep the existing app-wide sync indicator pipeline in `AppModel` as the single source of truth.
2. Redesign the indicator to read as a compact floating status chip instead of a text-heavy capsule.
3. Show a spinning sync affordance while syncing.
4. Transition to a green success state when sync completes and a red failure state when sync fails.
5. Keep account-unavailable handling aligned with the existing suppression rules so unavailable errors do not create extra toast noise.
6. Add or update tests and previews for the new indicator behavior.

## Plan
1. Extend `SyncBannerState` so the indicator can represent a short-lived success state in addition to syncing and failure.
2. Update `AppModel` sync-refresh handling to briefly show success after a completed sync and keep failure dismissal behavior concise.
3. Rebuild `SyncIndicatorView` as a compact top-right chip with explicit visuals for syncing, success, and failure.
4. Add lightweight animation for the syncing spinner and status transitions.
5. Add test coverage for the new `AppModel` sync indicator state transitions.
6. Add preview coverage for the indicator states.

## Acceptance Criteria
1. While syncing, the overlay appears as a compact top-right indicator rather than a large text toast.
2. Successful sync completion briefly transitions to a green success state.
3. Failed sync completion briefly transitions to a red failure state.
4. The indicator still stays hidden for account-unavailable cases already handled elsewhere.
5. Tests and previews cover the new behavior.

## Out of Scope
1. Changing CloudKit sync engine behavior.
2. Changing the detailed iCloud Sync screen contents.
3. Adding persistent history of sync attempts outside the current diagnostics screen.

- [x] Complete
