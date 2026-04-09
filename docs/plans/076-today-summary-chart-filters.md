# 076 Today Summary Chart Filters

## Goal
Add filter controls to the Today tab charts so caregivers can quickly focus on specific nappy and bottle-feed patterns during the day.

## Plan
1. Extend Today chart data to include filterable cumulative series for nappy and bottle dimensions that match requested views.
2. Add Today tab filter state and controls in `SummaryScreenView` for:
   - Nappies: pee, poo, mixed, poo including mixed, pee including mixed.
   - Bottle feeds: formula, breast milk, mixed, and inclusive variants.
3. Wire the selected filters to the chart series shown in the Today cards.
4. Add/update unit tests for the new filtered chart series behavior.
5. Run relevant tests and keep the change atomic.

- [x] Complete
