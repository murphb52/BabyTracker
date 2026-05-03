# 106 - Home Since-Last Event-Driven Refactor

## Summary
Refactor the Home screen `Since last` card so its rows are derived from enabled event kinds instead of a fixed set of hardcoded metrics. The card should naturally include Bath when enabled, respect event visibility settings, and keep active sleep as the only intentional special case. This work implements GitHub issue `#246`.

## Key Changes
1. Replace the hardcoded `CurrentStatusCardViewState` fields with a row-driven structure that tracks enabled event kinds, event-backed rows, and the explicit sleep summary needed for active-sleep handling.
2. Refactor `BuildCurrentStatusViewStateUseCase` to iterate `enabledEventKinds`, build generic latest-event rows for Bath, Breast Feed, Bottle Feed, and Nappy, and keep sleep as the only explicit exception.
3. Remove the aggregate `Feeds today` row so the card remains a pure since-last surface.
4. Update `HomeViewModel` and `CurrentStatusCardView` so the Home card renders generically from ordered event kinds and row data while preserving styling, empty placeholders, previews, and accessibility identifiers.
5. Add regression coverage for Bath, hidden event kinds, independent feed rows, and active-sleep suppression.

## Test Plan
1. Verify the use case returns row data only for supported enabled event kinds and suppresses the completed sleep row while an active sleep exists.
2. Verify Home status includes Bath naturally and updates when event visibility settings change.
3. Verify the SwiftUI card still renders deterministic accessibility identifiers and readable empty placeholders for enabled kinds with no events.

- [x] Complete
