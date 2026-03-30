# 025 Haptic Feedback

1. Add a semantic haptics boundary in `BabyTrackerFeature` with a small protocol, a semantic event enum, and a no-op default implementation.
2. Inject the haptics dependency into `AppModel` so user-visible outcomes can trigger feedback without coupling `BabyTrackerDomain` to UIKit.
3. Trigger haptics for the main outcomes:
   - success for create/update/archive/restore child flows
   - success for event log/edit/delete/undo flows
   - success for import completion, export readiness, and share-sheet preparation
   - selection feedback for child switching, timeline mode changes, and filter changes
   - warning for destructive hard delete completion
   - error for surfaced operation failures and sync failures shown to the user
4. Add the concrete `SystemHapticFeedbackProvider` in the app target and wire it through `AppContainer`.
5. Add focused `AppModel` tests with a spy provider to verify representative success, error, destructive, and sync-failure haptics.

- [x] Complete
