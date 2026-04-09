# 040 Child Switch Root Reset

## Goal
Make child switching consistently reset the app to the root workspace, open the Profile tab, and show clear feedback that the active child changed.

## Scope
1. Detect when the selected child actually changes.
2. Reset the navigation stack for real child switches.
3. Force the Profile tab to become active after a real child switch.
4. Show a brief transient message that confirms the child changed.

## Notes
- Child selection currently happens through `AppModel.selectChild(id:)`.
- Workspace tab selection currently lives inside `ChildWorkspaceTabView`.
- The app already has `navigationResetToken` and `transientMessage`, so this work should reuse those mechanisms.

## Plan
1. Move workspace tab selection into a shared feature-level type owned by `AppModel`.
2. Bind `ChildWorkspaceTabView` to the app model tab state instead of local `@State`.
3. Update `selectChild(id:)` to detect whether the incoming child differs from the current selection.
4. For real switches, reset the navigation stack, reset timeline state, switch to the Profile tab, and show `Child changed.`.
5. Keep no-op re-selection lightweight so it does not reset navigation or show redundant feedback.
6. Add tests for the real-switch and no-op paths.

## Acceptance Criteria
1. Switching to a different child returns the app to the root workspace.
2. The Profile tab is active after a real child switch.
3. A transient `Child changed.` message appears after a real child switch.
4. Re-selecting the already active child does not reset navigation or show the switch message.

## Out of Scope
1. Changing the child picker UI design.
2. Changing how child data is loaded or persisted.
3. Adding new transition animations for the tab switch.

- [x] Complete
