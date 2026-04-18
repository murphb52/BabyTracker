# 087 Home relative time compaction

## Goal
Make home-screen elapsed times more compact by using short relative strings for recent events and a day-aware fallback for older events.

## Approach
1. Update `ElapsedTimeFormatter` to use compact strings like `5m`, `1h`, and `1h 12m` for events under one day old.
2. Fall back to calendar-aware text for older events, such as `Yesterday at …` or weekday/time text.
3. Update the dedicated formatter tests to cover the new output.
4. Run the formatter test target to verify the change.

- [x] Complete
