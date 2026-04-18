# 083 Fix summary historical Today data

## Goal
Fix the Summary -> Today view so historical days, including Yesterday, calculate metrics and charts for the selected calendar day instead of drifting onto the following midnight boundary.

## Approach
1. Add an explicit selected-day path to `TodaySummaryCalculator` so historical summaries do not depend on a synthetic `now` timestamp.
2. Update `SummaryScreenView` to pass the selected day directly to the calculator.
3. Add regression tests covering historical-day summaries, with focused coverage on the sleep chart behavior.
4. Run the relevant feature tests to verify the fix.

- [x] Complete
