# 081 – Log a past sleep while a sleep is active

## Goal

Allow users to log a completed past sleep (with explicit start and end time) even when another sleep is currently in progress. Fixes the limitation reported in GitHub issue #205.

## Background

When a sleep is active, tapping the Quick Log sleep button shows the "End Sleep" sheet, which only allows ending the current active sleep. There is no path to log a missed nap or previous sleep session until the active sleep ends.

The domain layer (`LogSleepUseCase`) already supports logging a completed sleep without checking for an active session. The fix is entirely in the presentation layer.

## Approach

1. **`SleepEditorSheetView`** – Add an `initialIncludesEndTime` parameter so the "Already ended?" toggle can be pre-checked when opening the sheet in `.start` mode.

2. **`ChildEventSheet`** – Add a `.logPastSleep(suggestions:)` case that represents opening the log-past-sleep sheet.

3. **`CurrentSleepCardView`** – Add a `logPastSleep` callback and a "Log a past sleep" secondary button below the active sleep timer, visible only while a sleep is running.

4. **`ChildHomeView`** – Propagate the new `logPastSleep` closure down to `CurrentSleepCardView`.

5. **`ChildWorkspaceTabView`** – Wire `logPastSleep` to set `activeEventSheet = .logPastSleep(suggestions:)`, and handle the new sheet case by opening `SleepEditorSheetView` in `.start` mode with `initialIncludesEndTime: true`, calling `model.logSleep` on save.

## What is not changed

- `LogSleepUseCase` – already correct; no active-sleep guard.
- `StartSleepUseCase` – existing guard remains; this is a separate code path.
- The active sleep timer is unaffected.

## Tests

Added `logPastSleepSucceedsWhileAnotherSleepIsActive` to `AppModelTests` to verify:
- `logSleep` succeeds while an active sleep exists
- The active sleep is still present after the call
- Both sleep records exist in the repository

- [x] Complete
