# 042 Events History Date Filter, Date Headers, and Long-Press Actions

## Goal
Add three usability improvements to the Events tab:
1. Add a date range filter to the existing event filter sheet.
2. Group events by day with native section headers in the list.
3. Add long-press actions for editable events (Edit/Delete).

## Approach
1. Extend `EventFilter` in the Domain package with optional date range boundaries and include those boundaries in `isEmpty` and `matches(_:)`.
2. Add domain tests for date range filtering behavior.
3. Update `EventFilterView` to include a date range section with optional start/end dates and clear actions.
4. Update active filter pill rendering so date filters appear in the pills row and can be removed individually.
5. Add event-section view state in `EventHistoryViewModel` by grouping filtered events by day.
6. Update `EventHistoryView` to render `Section` blocks with sticky date headers and to include long-press context menu actions for Edit/Delete.
7. Add or update SwiftUI previews for touched SwiftUI files.
8. Build and run relevant tests before commit.

## Notes
- No GitHub issue was created in this environment; implementation is tracked via this plan document.

- [x] Complete
