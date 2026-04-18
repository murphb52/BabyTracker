## Goal

Move the timeline screen's initial viewport slightly upward so the current time is not positioned too close to the bottom edge on first load.

## Approach

- Keep the existing initial-scroll behavior based on the visible hour.
- Add a dedicated invisible scroll target slightly below each hour anchor in the day grid.
- Update the page view to use that offset target for initial scrolling so the viewport lands about 50 points higher.
- Verify the app still builds and the full test suite still passes.

- [x] Complete
