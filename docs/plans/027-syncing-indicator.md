# 027 – App-wide CloudKit syncing indicator

## Goal
Add a lightweight, app-wide sync indicator so caregivers can quickly see when CloudKit sync is active, and briefly surface failures without opening profile diagnostics.

## Approach
1. **Feature state plumbing (AppModel)**
   - Introduce a single source of truth for the indicator in `AppModel` (e.g. `syncBannerState`).
   - Route all existing sync refresh entry points (`load`, foreground refresh, post-write refresh) through one helper that:
     - sets indicator to syncing while work is running,
     - refreshes app state after completion,
     - maps failed sync results to a transient error indicator that auto-dismisses after a few seconds.

2. **Sync indicator UI component**
   - Add a reusable SwiftUI badge view in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views`.
   - Support at least:
     - syncing visual state (spinner),
     - failure/unavailable visual state (warning icon + message).
   - Keep styling simple and high-contrast for readability over any screen content.

3. **App-level placement**
   - Render the indicator in `Baby Tracker/App/AppRootView.swift` as a top-right overlay so it appears above all feature flows.
   - Keep existing error banner behavior intact.

4. **Validation coverage**
   - Add focused tests in `Baby TrackerTests/AppModelTests.swift` for indicator state transitions on successful and failed sync outcomes where practical.

- [x] Complete
