# 018 Stage 10: Timeline Week Strip

## Goal

Add a compact timeline mode in the Timeline tab that shows at least 7 days at once, supports horizontal scrolling into older days, and uses color sticks to represent event activity through each day.

## Approach

1. Add a domain use case that converts events into quarter-hour timeline slots.
- Build day columns from the earliest event day through today.
- Keep at least 7 days visible even for new profiles.
- Apply overlap precedence in this order: Sleep, Breast, Bottle, Nappy.

2. Add timeline strip state in the feature layer.
- Extend `TimelineScreenState` with a display mode and strip columns.
- Keep selected day behavior shared with the existing day calendar.

3. Add a top-right mode toggle on Timeline.
- Label should be `Week Strip` in day mode and `Day View` in strip mode.
- Keep day picker and Today button behavior unchanged.

4. Add a compact strip renderer.
- Render one slim vertical stick per day.
- Render 96 quarter-hour rows per day.
- Keep at least 7 columns visible at once.
- Allow horizontal scrolling back through older days.

5. Verify behavior with tests.
- Add domain coverage for quarter-hour slot generation and precedence.
- Add app-model coverage for strip columns and day anchoring.

- [ ] Complete
