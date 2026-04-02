# 038-day-view-5-minute-grid-density-tuning

## Goal
Make day view timeline cards less tall and denser while keeping event information readable.

## Approach
1. Update day-view rendering to use 5-minute slot math (matching the week strip concept) so event heights map directly to slot counts (e.g., 2 hours = 24 slots).
2. Reduce minimum block height and tune per-slot sizing so non-duration events (bottle, nappy) render at a compact but tappable minimum size.
3. Update day-view event content layout to fit icon + event name + detail (duration/feed amount) on one line with smaller typography.
4. For sleep blocks, render a second line with start and end sleep time.
5. Add/update a SwiftUI preview for `TimelineDayPageView` to cover the compact layout.
6. Run focused checks and update this plan to complete once implemented.

- [x] Complete
