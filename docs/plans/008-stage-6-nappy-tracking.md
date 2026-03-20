# 008 Stage 6: Nappy Tracking

## Summary

Implement nappy tracking on the existing child profile without redesigning the broader history UI. Reuse the existing domain, SwiftData, and CloudKit support that is already present, then add nappy quick log, edit/delete/undo, recent-history, and summary visibility.

## Plan

1. Complete the nappy event mutation and presentation layer.
   - Add `NappyEvent.updating(...)` so edits reuse the same validation path as create.
   - Include `pooColor` in nappy presentation text when present.
2. Extend derived feature state.
   - Add `LastNappySummaryViewState`, `LastNappySummaryCalculator`, and `RecentNappyEventViewState`.
   - Extend `CurrentStateSummaryViewState` and `ChildProfileScreenState` with nappy-specific data.
3. Update `AppModel` for nappy logging and editing.
   - Add `logNappy(...)` and `updateNappy(...)`.
   - Rename feed-specific event permissions to event-wide names.
   - Derive recent nappies and last nappy summary from the visible timeline.
4. Rework the child profile screen.
   - Add a quick-log nappy button and type chooser.
   - Add `NappyEditorSheetView` for quick log and edit flows.
   - Add a `Recent Nappies` section with edit/delete support.
   - Update the current-status card with `Last nappy` and event-first empty copy.
5. Expand automated coverage.
   - Add domain, repository, CloudKit mapper, `AppModel`, and calculator tests for nappy behavior.
   - Add UI coverage for nappy quick log and poo-color visibility.
   - Run `./scripts/validate.sh`.

- [x] Complete
