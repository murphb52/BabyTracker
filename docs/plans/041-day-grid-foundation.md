# 041 Issue 120: Timeline Day Grid Foundation and Replacement

## Summary

Implement issue `#120` in three passing slices on branch `codex/120-day-grid-foundation`.

The end state keeps both timeline modes:

- `Week View`: keep the current weekly strip overview
- `Day View`: replace the current block-based day timeline with a new 15-minute day grid

## Scope

1. Remove the old day timeline UI and temporary replace it with a placeholder.
2. Add domain day-grid layout types and a dedicated use case.
3. Build feature state and SwiftUI views for the new day grid while preserving the weekly strip.

## Slice Plan

1. Replace the current day page with a placeholder while leaving the week strip intact.
2. Add `BuildTimelineDayGridDatasetUseCase` and supporting domain models plus tests.
3. Replace the placeholder with the new day-grid feature state and UI.

## Tracking

- GitHub issue: `#120`
- Branch: `codex/120-day-grid-foundation`

- [ ] Complete
