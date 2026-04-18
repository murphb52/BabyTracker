# 081 Fix sleep today-chart historical truncation

## Goal
Fix the Today tab sleep chart so historical days use the full day of sleep data instead of truncating at the current clock hour.

## Approach
1. Inspect how the Summary screen builds `TodaySummaryData` for selected days.
2. Update date handling so non-today selections calculate chart data through the end of the selected day.
3. Verify the feature package tests still pass.

- [x] Complete
