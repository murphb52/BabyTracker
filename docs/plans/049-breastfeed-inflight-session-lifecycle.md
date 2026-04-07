# 049 — Breast Feed In-Flight Session Lifecycle

## Goal

Make breast feeding behave like sleep tracking:

- start a session and persist it immediately
- keep it resumable/editable while in flight
- end it later (including from Home)
- show active breast feed status on Home similar to current sleep status
- sync the in-flight and completed states through existing CloudKit record types

## Approach

1. **Domain session model parity with sleep**
   - Update `BreastFeedEvent` to allow an in-flight session (`endedAt == nil`).
   - Add dedicated use cases:
     - `StartBreastFeedUseCase`
     - `EndBreastFeedUseCase`
     - `ResumeBreastFeedUseCase`
   - Extend `EventRepository` with `loadActiveBreastFeedEvent(for:)`.

2. **Persistence support for active breast feed**
   - Make stored breast feed `endedAt` optional.
   - Update mapping/save/load logic for active sessions.
   - Implement `loadActiveBreastFeedEvent` in `SwiftDataEventRepository`.

3. **Feature/AppModel workflow updates**
   - Track `activeBreastFeed` in `AppModel` alongside `activeSleep`.
   - Add AppModel methods for start/end/resume/update of in-flight breast feed.
   - Keep existing quick-log manual save flow working.

4. **Home indicator and action flow**
   - Add `CurrentBreastFeedCardViewState` and `CurrentBreastFeedCardView`.
   - Show active breast feed section on Home (similar visual hierarchy to sleep).
   - Wire “Breast Feed” quick action to start/end contextually.

5. **Sheet and event action updates**
   - Extend event action payload and sheet routing for active breast feed:
     - start
     - end
     - edit completed
     - resume completed

6. **CloudKit mapper compatibility (prefer no schema changes)**
   - Keep `BreastFeedEvent` record type and existing field names.
   - Treat `endedAt` as optional in mapper read/write.
   - Avoid adding new CloudKit record types.

7. **Validation and tests**
   - Add/update tests covering:
     - start in-flight breast feed
     - end in-flight breast feed
     - resume completed breast feed
     - active breast feed retrieval
     - Home view model active breast feed state

## Notes

- This plan intentionally avoids CloudKit schema expansion by reusing existing fields and record type.
- Migration risk is limited to local model optionality (`StoredBreastFeedEvent.endedAt`).

- [x] Complete
