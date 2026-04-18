# 086 Line chart average always visible

## Goal
Always show the average trendline on line charts, while keeping bar-chart averages interaction-only.

## Approach
1. Update the shared cumulative line chart view so its average series is always rendered.
2. Leave bar-chart behavior unchanged.
3. Run the targeted summary calculator test command to verify the change still compiles cleanly.

- [x] Complete
