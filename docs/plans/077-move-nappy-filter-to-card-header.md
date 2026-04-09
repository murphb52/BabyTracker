## Goal

Move the Today summary nappy chart filter from the content stack to the top-right corner of the nappy card.

## Approach

1. Keep the change in `SummaryScreenView` so the layout update stays local to the existing summary UI.
2. Replace the nappy card's standard header with a simple `HStack` that keeps the title on the left and the filter menu on the right.
3. Leave the chart, filter behavior, and other summary cards unchanged.

## Notes

- This is a small UI tweak, so no separate GitHub issue is needed.

- [x] Complete
