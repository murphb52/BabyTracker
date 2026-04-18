# 084 Align summary and trends sleep totals

## Goal
Make the Summary -> Today sleep totals for a selected day match the Trends tab by counting only the minutes that actually overlap that calendar day.

## Approach
1. Update `TodaySummaryCalculator` sleep aggregation so selected-day totals are based on day-overlap minutes, not whole sessions keyed by `occurredAt`.
2. Keep the hourly sleep chart and day-level totals driven by the same overlap logic.
3. Add regression tests covering overnight sleep that spans two days and verify Today and Trends now agree for the selected day.
4. Run the focused summary calculator tests.

- [x] Complete
