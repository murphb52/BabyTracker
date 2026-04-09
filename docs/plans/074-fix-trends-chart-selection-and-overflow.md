# 074 Fix Trends Chart Selection And Overflow

GitHub issue: #176

## Goal

Fix the Trends charts on the Summary tab so tapping a bar always shows the value for the exact tapped day and chart labels/callouts no longer overflow above the chart area.

## Plan

1. Update the single-series Trends chart to use a unique per-point x-domain value instead of the visible weekday label.
2. Apply the same identity fix to the stacked nappy chart so repeated weekday labels do not confuse selection or rendering.
3. Add explicit Y-axis headroom so top labels and selection callouts fit within the chart bounds while keeping the axis stable during selection.
4. Add focused tests around the chart point mapping and headroom calculations.

- [x] Complete
