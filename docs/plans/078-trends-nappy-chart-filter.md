## Goal

Add a filter to the Trends nappy chart so the user can switch between the full stacked view and specific nappy categories.

## Approach

1. Add a trends-specific nappy filter in `SummaryScreenView`.
2. Keep the existing stacked chart for the `All` option.
3. Render a simple single-series bar chart for filtered views so the change stays local and readable.

## Notes

- This is a small UI enhancement, so no separate GitHub issue is needed.

- [x] Complete
