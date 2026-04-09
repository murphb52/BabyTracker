# 018 Summary Tab Metrics

## Goal
Add a new Summary tab that highlights top-level baby care metrics and provides deeper insights for today, 7 days, 30 days, and all time.

## Plan
1. Add summary screen state to the child profile so the tab can derive metrics from existing event data.
2. Add a focused summary metrics calculator that computes top-level and in-depth metrics from a selectable time range.
3. Build a new SwiftUI Summary tab with card-based Liquid Glass styling, segmented time range selection, top metrics, deeper metrics, and two key chart sections.
4. Add tests for the summary calculator to keep calculations predictable and safe.
5. Wire the Summary tab into the existing child workspace tab navigation.

- [x] Complete
