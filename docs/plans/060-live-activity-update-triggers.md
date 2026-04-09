# 060 - Live activity update triggers without polling

## Goal
Remove foreground polling and keep live activity synchronization event-driven so updates happen only when data or selection state changes.

## Plan
1. Remove the 30-second polling task from `AppRootView`.
2. Keep `UpdateFeedLiveActivityUseCase` execution tied to known state-change paths in `AppModel` (refresh completion and explicit enable/disable toggles).
3. Verify existing AppModel live activity tests still cover write-triggered synchronization paths.

- [x] Complete
