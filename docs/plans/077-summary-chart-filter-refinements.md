## Goal

Refine the Summary screen chart filters so the Today and Trends cards are more consistent, easier to scan, and more useful.

## Approach

1. Move the Today nappy and bottle filter menus into the top-right corner of their cards so the controls sit with the card headers instead of breaking up the content stack.
2. Add a Trends nappy filter that supports the stacked `All` view plus focused single-series views for wet, dirty, mixed, dry, and the mixed-inclusive options.
3. Extend the Trends bottle data model to keep per-type daily totals, then add a matching bottle filter for total, formula, breast milk, mixed, and mixed-inclusive views.
4. Shorten the bottle filter `All` label so the Today and Trends menus stay compact and aligned with the other filter labels.

## Notes

- This refinement work stays in `SummaryScreenView` plus the trends bottle data model.
- No separate GitHub issue was needed because the work remained a small UI-focused polish pass.

- [x] Complete
