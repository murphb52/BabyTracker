# 083 Drift reminder threshold hardening

## Goal

Make drift reminders feel less premature by improving threshold calculations and scheduling behavior for sleep and inactivity reminders.

## Approach

1. Improve sleep drift thresholding so it is less sensitive to short naps and can use context-aware history (night vs daytime), with a hard lower bound.
2. Improve inactivity drift thresholding to use more robust cadence data and avoid sleep-related gaps skewing results.
3. Prevent inactivity reminders from being scheduled while an active sleep session is in progress.
4. Replace fixed overdue reminder grace timing with an adaptive delay based on the computed threshold.
5. Add focused domain and feature tests for new threshold and scheduling behavior.

## Notes

- This is a targeted behavior change without broad architecture refactoring.
- Existing caps and fallbacks remain in place, with safer minimum floors to avoid “too soon” reminders.

- [x] Complete
