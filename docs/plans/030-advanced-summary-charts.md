# 030 Advanced Summary Charts

## Goal
Expand the Summary experience so users can drill into richer feed, sleep, and nappy insights, including viewing a specific day's summary and navigating to a deeper metrics screen from the existing Summary tab.

## Scope
1. Keep the existing Summary tab as the top-level overview.
2. Add a new secondary summary destination, reachable from the current Summary screen, for deeper charts and metrics.
3. Add support for a specific-date summary view in addition to the current range-based summary options.
4. Improve visual clarity on the main Summary screen by using event accent colors more intentionally.
5. Organize advanced insights by event type instead of placing every metric in one long undifferentiated page.

## Notes
- The current summary implementation is `SummaryScreenView` backed by `SummaryMetricsCalculator`.
- The current summary supports `today`, `7 days`, `30 days`, and `all time`, but not a user-picked day.
- Existing summary cards and charts are intentionally simple; this work should build on that foundation rather than replacing it with a dense analytics dashboard.

## Plan
1. Review the current summary snapshot and identify which additional derived metrics belong in the existing calculator versus a new advanced summary calculator.
2. Add navigation from the Summary screen to a new "More Information" or similarly named destination.
3. Introduce date selection for a specific-day summary, using the selected date to filter events predictably.
4. Split advanced content into clear sections such as:
   - feeds
   - sleep
   - nappies
   - overall activity
5. Add a first set of higher-value metrics, for example:
   - feed count by type
   - average bottle volume
   - sleep totals and average sleep block for the chosen period
   - nappy distribution by type
   - busiest times of day
6. Keep charts simple, readable, and native to SwiftUI so they remain easy to maintain.
7. Add event-color accents to the existing Summary overview cards and charts where they improve scanning.
8. Add tests for any new summary derivation logic, especially date filtering and event-specific aggregates.
9. Run targeted validation for empty states and low-data scenarios.

## Acceptance Criteria
1. The Summary tab includes a clear path to a deeper summary page.
2. Users can choose a specific date and see metrics for that day only.
3. Advanced summary content is organized by event type or insight category rather than as one large mixed list.
4. The existing Summary overview remains lightweight and easy to scan.
5. New chart and metric colors align with the app's event accents without hurting readability.
6. Derived calculations are covered by tests where practical.

## Out of Scope
1. Exporting charts as images or reports.
2. Clinician-specific report generation.
3. Overly dense analytics or highly custom charting infrastructure.

- [ ] Complete
