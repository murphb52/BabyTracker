# 048 Home Sync Status Entry

## Goal
Implement GitHub issue [#102](https://github.com/murphb52/BabyTracker/issues/102) by adding a Home surface that summarizes current sync state and opens the existing iCloud Sync details screen.

## Scope
1. Add a sync summary section to the Home screen.
2. Reuse the existing `CloudKitStatusViewState` as the source of truth for status, pending state, and unavailable handling.
3. Provide a clear disclosure entry point from Home into the detailed `iCloud Sync` screen.
4. Keep the Home UI lightweight and readable beside the current status and quick-log sections.
5. Add or update previews for the touched SwiftUI views.

## Plan
1. Extend Home screen state with the information needed to render a sync summary row or card.
2. Shape the Home sync state from `AppModel` using the existing sync summary data instead of duplicating copy logic in the view.
3. Add a Home sync section in `ChildHomeView` with status, supporting detail, and disclosure styling.
4. Wire the Home section to navigate to `ChildProfileSyncView`.
5. Add preview coverage for meaningful sync states, including synced, waiting to sync, and unavailable.

## Acceptance Criteria
1. Home shows whether the user is syncing, waiting to sync, synced, or unavailable.
2. Home includes a disclosure indicator that opens the detailed iCloud Sync screen.
3. The Home sync summary uses the same underlying sync status information as the existing sync diagnostics flow.
4. Touched SwiftUI views include useful previews.

## Out of Scope
1. Creating a second sync diagnostics screen.
2. Changing sharing flows or caregiver management.
3. Adding manual sync controls to Home beyond navigation to the existing screen.

- [x] Complete
