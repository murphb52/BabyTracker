## Goal

Add a filter to the Trends bottle chart so the user can switch between total bottle volume and milk-type-specific views.

## Approach

1. Extend trends bottle day data to keep per-type milliliter totals.
2. Add a trends-specific bottle filter in `SummaryScreenView`.
3. Reuse the existing single-series bar chart for the filtered views.

## Notes

- This is a small UI enhancement, so no separate GitHub issue is needed.

- [x] Complete
