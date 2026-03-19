# 006 Stage 4: Feed Event Editing, Delete, Undo, and Empty States

## Summary

Implement Stage 4 on top of the current Stage 3 feed logging flow. Keep the UI focused on breast-feed and bottle-feed events, add a compact recent-feed history to the child profile screen, support editing and deleting feed events for owners and active caregivers, and provide an in-session undo path after delete.

## Plan

1. Extend domain permissions and mutation helpers.
   - Add explicit event edit and delete access actions.
   - Allow active caregivers and owners to edit and delete events.
   - Add helpers to update breast-feed and bottle-feed events and to restore deleted metadata.
2. Extend feature state for recent feed history and undo.
   - Add a recent-feed view state with display text and edit payload data.
   - Add recent-feed rows and feed-management permissions to the child profile state.
   - Update `AppModel` to derive feed summary and recent feeds from one timeline load.
   - Add in-memory delete undo state and methods for update, delete, and undo.
3. Rework feed editing UI on the child profile screen.
   - Extract breast-feed and bottle-feed editors into standalone sheet views.
   - Reuse the same editors for quick log and edit flows.
   - Add a recent-feed section with tap-to-edit and swipe edit/delete actions.
   - Add simple feed empty-state copy when there is no feed history.
4. Add a bottom undo banner at the app root.
   - Show a temporary undo banner after confirmed delete.
   - Keep existing error handling and sync messaging unchanged.
5. Add and update automated coverage.
   - Add domain, repository, `AppModel`, and UI tests for edit, delete, undo, and empty-state behavior.
   - Run `./scripts/validate.sh`.

- [x] Complete
