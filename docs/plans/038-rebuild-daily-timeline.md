# 038 — Rebuild Daily Timeline

**Issue:** [#15](https://github.com/murphb52/BabyTracker/issues/15)

## Problem

The current daily timeline (`TimelineDayPageView`) shows one day at a time in a tall vertical scroll. Navigating between days requires swiping or pressing buttons, which makes scanning across days slow.

## Approach

Replace the single-day pager with a multi-day grid — like the weekly strip view, but with full event block content instead of coloured slots. Each of the 7 days in the current week appears as a column. Time runs vertically; days run horizontally. ~12 hours are visible at once; users scroll vertically for more hours and horizontally for different days.

## Changes

### `TimelineDayPageState` + `AppModel`
- Add `dayNumberTitle: String` to `TimelineDayPageState` for column headers.
- Set `dayNumberTitle: day.formatted(.dateTime.day())` in `AppModel.loadTimelinePages`.

### NEW `TimelineDayGridView`
- Layout: sticky header row (day names) + `ScrollView(.vertical)` containing `hourAxis` + `ScrollView(.horizontal)` with `LazyHStack` of day columns.
- Each column is a `ZStack` with hour-row backgrounds and event blocks positioned by `startMinute`/`endMinute`.
- Block rendering reuses the same helpers as the old `TimelineDayPageView`.
- Horizontal scroll syncs with the sticky day header via `.scrollPosition(id:)`.
- Auto-scrolls to current hour on appear; scrolls selected column into view on day change.

### `TimelineScreenView`
- Replace `TabView + TimelineDayPageView` with `TimelineDayGridView`.
- Remove the day-button row from the pinned header (day names are now visible inside the grid).

### Delete `TimelineDayPageView`
No longer needed.

## Files

| Change | File |
|--------|------|
| Modify | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/TimelineDayPageState.swift` |
| Modify | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift` |
| Add    | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/TimelineDayGridView.swift` |
| Modify | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/TimelineScreenView.swift` |
| Delete | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/TimelineDayPageView.swift` |
