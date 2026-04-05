# 043 Issue 140: Grid Calendar Picker Sheet Improvements

## Summary

Implement issue `#140` on branch `codex/issue-140-grid-calendar-picker-sheet-improvements`.

The timeline day picker should present at a tighter height so the graphical calendar fits with padding instead of expanding to a large sheet with empty space above and below.

## Scope

1. Update the timeline day picker sheet presentation to use SwiftUI's fitted sizing on the iOS 26 target.
2. Keep the existing calendar picker behavior, controls, and navigation structure unchanged.
3. Align package deployment declarations with the app's iOS 26 target so the fitted presentation API can be used without legacy fallback code.
4. Verify the app still builds after the presentation change.

## Tracking

- GitHub issue: `#140`
- Branch: `codex/issue-140-grid-calendar-picker-sheet-improvements`

- [x] Complete
