## Goal

Simplify drift reminder timing so reminders no longer fire based on short historical averages.

## Approach

1. Keep drift threshold logic inside the existing domain use cases.
2. Replace the adaptive inactivity threshold with a fixed 12-hour threshold.
3. Replace the adaptive sleep threshold with a fixed 16-hour threshold.
4. Add domain tests that verify both use cases return the new fixed thresholds regardless of event history.

- [x] Complete
