# 073 Summary chart selection axis stability

## Goal

Fix the Summary tab interaction bug where tapping a chart bar shows the callout but also causes y-axis values to change.

## Approach

1. Identify the Summary chart views that use selection callouts and still rely on automatic y-axis scaling.
2. Add explicit, data-driven y-axis domains so showing the selection callout does not alter chart scaling.
3. Keep the existing selected-bar emphasis behavior while preserving chart layout stability.
4. Add/update SwiftUI previews for touched chart views.
5. Run focused package tests to confirm no regressions.

- [x] Complete
