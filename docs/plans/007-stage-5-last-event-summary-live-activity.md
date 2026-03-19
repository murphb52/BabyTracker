# 007 Stage 5: Last Event Summary and Live Activity

## Summary

Implement Stage 5 as two connected pieces: an all-events current-state hero card on the child profile, and a feed-only Live Activity for the selected child.

## Plan

1. Replace the feed-only profile summary with shared derived current-state data.
   - Add all-event last-summary and feed-status view-state types.
   - Derive last event, last feed, feeds today, recent feeds, and the live-activity snapshot from one visible timeline load.
   - Keep derived data in feature code rather than persistence.
2. Rework the child profile summary UI.
   - Replace the row-based feeding section with a compact current-status card.
   - Show the latest event, last logged time, time since last feed, and feeds today.
   - Keep empty-state copy aligned with the new section order.
3. Add feed Live Activity infrastructure.
   - Introduce a shared `BabyTrackerLiveActivities` package for Activity attributes.
   - Add a Live Activity widget extension target and app-side manager.
   - Keep updates local-only and fail gracefully when unavailable.
4. Expand coverage.
   - Add calculator tests for all-event summaries and feed recency edge cases.
   - Update `AppModel` and UI tests for mixed timelines and the new card identifiers.
   - Run `./scripts/validate.sh` after each logical slice and when the stage is complete.

- [x] Complete
