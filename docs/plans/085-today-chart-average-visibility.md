# 085 Today chart average visibility

## Goal
Show the average trendline continuously on Today charts, while keeping it interaction-only for historical-day charts.

## Approach
1. Update the cumulative chart view so average-line visibility depends on whether the chart is rendering Today or a historical day.
2. Keep the current interaction-driven callout behavior unchanged.
3. Verify the project still builds through the targeted test command already used for the summary calculators.

- [x] Complete
