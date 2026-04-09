# 011 Stage 8: Timeline View

## Summary

Implement Stage 8 as a dedicated timeline screen reachable from the child profile, while keeping the existing `Recent Feeds`, `Recent Sleep`, and `Recent Nappies` sections in place.

The timeline will show one selected day at a time, default to today, and let the user move backward and forward by day. Within a day, events will render in chronological order from earliest to latest so gaps and overlaps are easy to scan. Timeline rows will open the same edit/end flows already used elsewhere, and delete/undo behavior will stay consistent with the current profile experience.

## Scope

1. Add a dedicated timeline destination from the child profile.
2. Add selected-day timeline state to the feature layer.
3. Render a unified mixed-event day view for feeds, sleep, and nappies.
4. Show simple overlap and large-gap cues in the timeline.
5. Reuse existing edit/end-sleep, delete, and undo flows from timeline rows.
6. Show simple empty and sync-status states on the timeline screen.
7. Add unit and UI coverage for day navigation, ordering, overlap/gap presentation, and row actions.

## Implementation Plan

1. Add the Stage 8 planning document.
   - Create this document under `/docs/plans`.
   - Keep it as the implementation reference for Stage 8.
2. Add timeline-specific feature state.
   - Create `TimelineScreenState` in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/`.
   - Create `TimelineEventRowViewState` in its own file.
   - Create `TimelineEventActionPayload` in its own file for row tap routing.
   - Keep these types explicit rather than folding them into the existing recent-event view states.
3. Extend child-profile feature state and app-model state.
   - Add `timeline: TimelineScreenState` to `ChildProfileScreenState`.
   - Add a private selected-day property to `AppModel`, normalized to start-of-day.
   - Reset the selected day to today when switching children.
   - Add public `AppModel` methods for previous day, next day, and jump-to-today navigation.
4. Derive timeline screen state in `AppModel`.
   - Keep the current full visible-timeline load for current status, recent sections, and live-activity state.
   - Reuse `loadEvents(for:on:calendar:includingDeleted:)` for the timeline screen.
   - Sort selected-day events oldest to newest before mapping rows.
   - Build row time text using event-specific rules for feeds, nappies, completed sleep, and active sleep.
5. Lock down grouping, overlap, and gap rules.
   - Group events by the existing `metadata.occurredAt` day.
   - Treat breast feeds and sleep as interval events, active sleep as open-ended, and bottle/nappy events as point-in-time.
   - Show overlap text when an event starts before the previous event ends.
   - Show gap text only when the gap between adjacent events is at least 2 hours.
6. Add the timeline screen UI.
   - Create `Baby Tracker/App/Stage1/TimelineScreenView.swift`.
   - Push it from `ChildProfileView` using `NavigationLink`.
   - Add a `History` section with a `Timeline` entry point.
   - Render day navigation, optional sync messaging, timeline rows, and an empty-day state.
7. Reuse existing edit/delete/end flows from timeline rows.
   - Extend `ChildProfileView` sheet and delete routing so timeline rows use the existing editors and delete confirmation behavior.
   - Add timeline row identifiers using `timeline-event-<uuid>`.
8. Handle sync, empty, and loading states deliberately.
   - Keep timeline sync messaging at screen level only.
   - Use reassuring pending-sync copy.
   - Reuse the existing app/profile loading behavior.

## Public API / Type Changes

- `ChildProfileScreenState`
  - add `timeline: TimelineScreenState`
- `AppModel`
  - add `showPreviousTimelineDay()`
  - add `showNextTimelineDay()`
  - add `jumpTimelineToToday()`
- New feature types
  - `TimelineScreenState`
  - `TimelineEventRowViewState`
  - `TimelineEventActionPayload`

## Test Cases

1. App-model / feature-state tests.
   - A mixed day with breast feed, bottle feed, nappy, and sleep produces one unified timeline in oldest-to-newest order.
   - Selected-day navigation moves backward and forward correctly and disables forward navigation on today.
   - Timeline state resets to today when switching children.
   - Completed sleep rows use end-day grouping and show the full start/end range.
   - Active sleep rows appear on their start day and route to the end-sleep flow.
   - Gap text appears only when the gap is at least 2 hours.
   - Overlap text appears when a feed occurs during sleep or another interval event.
   - Timeline sync message appears only when `cloudKitStatus.state != .upToDate`.
2. Repository tests.
   - Extend day-boundary coverage so selected-day queries are protected for mixed event types.
   - Include a sleep that spans midnight and verify the grouping rule based on `metadata.occurredAt`.
3. UI tests.
   - User can open the timeline screen from the child profile.
   - User can navigate to a previous day and jump back to today.
   - Mixed events render on the same timeline screen.
   - Tapping a timeline bottle-feed row opens the bottle-feed editor.
   - Tapping an active-sleep timeline row opens the end-sleep sheet.
   - Deleting a timeline row shows the existing undo banner and removes the row from the selected day.
   - Empty selected-day state appears for a day with no events.
4. Validation.
   - Run `./scripts/validate.sh` after implementation.

## Acceptance Criteria

- Child profile contains a clear entry point to a dedicated timeline screen.
- Timeline defaults to today and supports previous/next day navigation.
- Timeline shows a unified day view across all implemented event types.
- Rows are chronological within the selected day.
- Large gaps and overlaps are understandable without a custom graphical timeline.
- Timeline rows lead into the correct edit or end-sleep flows.
- Delete and undo behavior matches the rest of the app.
- Pending sync is communicated without implying data loss.
- Existing recent sections continue to work unchanged.

## Assumptions and Defaults

- The timeline remains a dedicated screen, not a replacement for the existing recent sections.
- The dedicated screen is pushed from `ChildProfileView` with `NavigationLink`, not introduced as a new root route.
- The selected day is stored in `AppModel`, not local view state.
- Within a selected day, timeline rows are oldest-to-newest even though the repository’s general timeline is newest-to-oldest.
- Grouping follows current `metadata.occurredAt` semantics rather than introducing cross-day event splitting.
- Overlap is communicated with simple text, not lane-based graphics.
- Gap messaging appears only for 2+ hour gaps to avoid visual noise.
- Pending sync is a screen-level message only in Stage 8.
- No performance refactor of the broader event-loading model is included here; Stage 9 can optimize data loading later if needed.

- [x] Complete
