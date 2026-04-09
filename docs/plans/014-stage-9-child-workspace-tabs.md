# 014 Stage 9: Child Workspace Tab Restructure

## Summary

Restructure the child experience into four sibling tabs:

1. `Home`
2. `Events`
3. `Timeline`
4. `Profile`

`Home` becomes the default tab and owns current status, quick logging, and recent mixed activity. `Events` becomes the full newest-first mixed event history. `Timeline` remains the day calendar. `Profile` keeps child details, sharing, invites, sync, switching child, and archiving.

## Implementation

1. Replace the old two-tab child shell with a four-tab workspace shell.
2. Move event sheet, delete confirmation, share sheet, edit-child sheet, archive confirmation, and nappy quick-log dialog ownership into the shared shell.
3. Introduce shared mixed-event card state and a generic event action payload in `BabyTrackerFeature`.
4. Derive `Home` and `Events` screen state from the existing full visible timeline in `AppModel`.
5. Build a new `Home` screen with:
   - current status card
   - 2-column quick-log grid
   - mixed recent activity feed
6. Build a new `Events` screen with mixed event cards in descending order and edit/delete behavior.
7. Keep the existing `Timeline` day calendar tab and rewire it to use the shared shell-owned event flows.
8. Simplify `Profile` so it only contains child details, sharing, pending invites, caregivers, sync, switch child, and archive actions.
9. Update unit tests and UI tests to target the new tab structure and shared history model.

## Defaults

- `Home` is the default selected tab.
- `Home` shows the 6 most recent mixed events.
- `Events` is an ungrouped descending list with card presentation.
- `Profile` keeps sharing and invite content together rather than splitting another tab.
- `Timeline` remains unchanged functionally.

- [x] Complete
