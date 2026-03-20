# 012 Stage 8: Timeline Swipe, Picker, Tighten

## Goal

Improve the timeline calendar so day changes feel faster and the screen is denser.

## Approach

1. Add direct timeline day selection in the feature model.
- Introduce a `showTimelineDay(_:)` API in `AppModel`.
- Normalize the chosen day and keep future dates clamped to today.

2. Add faster day navigation in the timeline screen.
- Support horizontal swipes to move backward and forward by day.
- Add a calendar picker entry point in the header that opens a graphical day picker.

3. Tighten the vertical calendar layout.
- Reduce the hour row height and surrounding spacing.
- Keep blocks readable while shortening the overall scroll length.

4. Update validation coverage.
- Extend UI coverage for swipe navigation and the day picker.
- Run `./scripts/validate.sh`.

- [x] Complete
