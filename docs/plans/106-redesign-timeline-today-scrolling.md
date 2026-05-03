# 106 - Timeline Today Scrolling Redesign

## Summary
Implement issue [#247](https://github.com/murphb52/BabyTracker/issues/247) by replacing day-mode swipe pagination with a single selected-day timeline grid that scrolls horizontally across event-type columns and keeps the event-type header row visible while the timeline content scrolls vertically.

## Key Changes
1. Timeline screen navigation
- Remove the day-mode `TabView` paging container and the `DragGesture` swipe-to-change-day behavior from `TimelineScreenView`.
- Keep the existing explicit day controls: previous/next buttons, weekday strip, Today button, and calendar picker.
- In day mode, render only the currently selected `TimelineDayGridPageState`; changing days continues to go through `TimelineViewModel.showPreviousDay()`, `showNextDay()`, `showDay(_:)`, and `jumpToToday()`.

2. Day grid layout and scrolling
- Refactor `TimelineDayGridPageView` and `TimelineDayGridView` so the grid becomes a two-axis layout with a sticky event-type header row, a horizontally scrollable column area, and the existing time gutter pinned on the left.
- Use a single shared horizontal scroll position in the feature view layer so the header and body stay aligned and the horizontal position is preserved across day changes and state refreshes while the Timeline screen remains active.
- Keep the current initial vertical auto-scroll behavior to the visible hour for the selected day.
- Keep column ordering, column titles, icons, colors, grouping behavior, edit opening, and delete interactions unchanged.

3. View composition and identifiers
- Keep the domain grid dataset builder unchanged; this is a presentation refactor only.
- Reuse `TimelineDayGridColumnKind` as the stable horizontal column ordering; do not add new domain identifiers.
- Add or update accessibility identifiers so UITests can target the sticky header, horizontal column scroll area, and vertical timeline scroll area.

## Test Plan
1. AppModel and feature regression
- Keep existing timeline data, ordering, grouping, and event action payload tests passing.
- Keep day-navigation tests, but validate navigation only through explicit controls instead of swipe gestures.

2. UI tests
- Replace the current swipe-based day-navigation UITest with coverage that uses previous/next or weekday buttons and verifies the selected day and content update correctly.
- Keep coverage that the day grid still exposes tappable event items after the layout refactor.
- Add UITest coverage that the horizontal column scroll area exists in day mode and that returning to Today still shows the selected-day grid.

3. Preview and manual verification
- Add a narrow-width timeline preview that forces horizontal overflow.
- Verify sticky headers remain visible while vertically scrolling long timeline content.
- Verify horizontal position is preserved when switching days and when the selected day refreshes.
- Verify the current-time indicator, grouped-event sheet, single-event edit opening, and delete confirmation still work.

## Assumptions
- Keep the current explicit day navigation UI; only swipe-based day changes are removed.
- The sticky header row contains the existing icon and title chips only.
- Horizontal position preservation is scoped to the active Timeline screen session and is not persisted across app launches.
- Week mode is out of scope except for any harmless fallout from removing day-mode paging.

- [x] Complete
