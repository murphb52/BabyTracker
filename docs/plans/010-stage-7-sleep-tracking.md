# 010 Stage 7: Sleep Tracking

## Summary

Implement sleep tracking on the child profile using the existing sleep domain, persistence, and sync support. This stage adds start/end sleep flows, completed-sleep editing, delete/undo support, active-session recovery, and sleep visibility in current status and recent history.

## Plan

1. Extend the sleep domain and app model.
   - Add `SleepEvent.updating(...)` so start, end, and edit flows share one validation path.
   - Add app-model sleep mutations for start, end, and completed-session edits.
   - Enforce one active sleep session per child.
2. Derive sleep feature state.
   - Add active-sleep, last-sleep, and recent-sleep view state types.
   - Load the active sleep session from the repository during refresh.
   - Keep recent sleep rows limited to completed sessions in newest-first order.
3. Add the sleep UI.
   - Add a contextual quick-log sleep button that switches between `Start Sleep` and `End Sleep`.
   - Add `SleepEditorSheetView` for start, end, and edit flows.
   - Show last sleep status in the current-status card.
   - Add a `Recent Sleep` section with edit/delete support for completed sessions.
4. Expand automated coverage.
   - Add domain, calculator, app-model, mapper, and UI coverage for sleep behavior.
   - Verify active-session recovery, single-session enforcement, delete/undo, and validation states.
5. Validate the full stage.
   - Run `./scripts/validate.sh`.

- [x] Complete
