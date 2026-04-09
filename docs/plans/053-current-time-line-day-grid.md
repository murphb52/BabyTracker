# 053 – Show current time line on day grid

## Goal
Add a thin current-time indicator to the timeline day grid so today's page clearly shows where "now" sits within the 24-hour chart.

## Approach
1. Update `TimelineDayGridView` to overlay a horizontal indicator line when the rendered day is today.
2. Compute the indicator position from current minutes elapsed in the day and clamp it to the grid bounds.
3. Keep the indicator width aligned to the event grid columns (excluding the hour label gutter) so it spans the chart area.
4. Use a periodic timeline refresh so the line advances automatically while the view is visible.
5. Render the indicator below event blocks so active cards stay visually prioritized.
6. Add/update previews to make the indicator behavior easy to validate during development.

## Verification
1. Build the app target/package.
2. Run relevant Swift package tests.

- [x] Complete
