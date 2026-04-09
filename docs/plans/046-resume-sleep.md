# 046 - Resume Sleep

## Goal

Allow users to resume an accidentally ended sleep session from the sleep edit screen.

## Approach

1. Add `ResumeSleepUseCase` in the domain layer — clears `endedAt`, making the sleep active again.
2. Add `AppModel.resumeSleep(id:startedAt:)` following the existing sleep method pattern.
3. Add an optional `resumeAction` callback to `SleepEditorSheetView` shown only in `.edit` mode.
4. Wire the callback in `ChildWorkspaceTabView` when presenting the edit sheet.
5. Add tests for `ResumeSleepUseCase`.

- [ ] Complete
