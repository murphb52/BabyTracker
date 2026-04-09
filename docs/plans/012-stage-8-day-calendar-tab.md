# 012 Stage 8: Day Calendar Tab

## Goal

Replace the list-based timeline with a 24-hour day calendar, remove clash/gap helper text, and expose the calendar as its own tab in the child experience.

## Approach

1. Replace timeline row state with positioned calendar block state.
- Keep the existing day selection and event action payloads.
- Derive visible start and end minutes within the selected day.
- Assign simple overlap lanes so concurrent events can render side by side instead of relying on clash text.

2. Rebuild the timeline screen as a vertical 24-hour calendar.
- Render the full day with hour markers.
- Scroll to the current hour when the selected day is today.
- Show feeds and nappies as short blocks and sleep as stretched blocks.
- Keep tap-to-edit or tap-to-end behavior on the event blocks.

3. Move profile and timeline into a shared tab shell.
- Remove the in-profile history entry point.
- Make `Profile` and `Timeline` sibling tabs for the child profile route.
- Update unit and UI tests to target the tabbed day-calendar experience.

## Validation

- Run `./scripts/validate.sh`.

- [x] Complete
