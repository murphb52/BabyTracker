# 050 Respect preferred feed volume unit across bottle displays

1. Add a shared bottle-volume presentation helper so summary, chart, and timeline surfaces format bottle amounts through one path instead of hardcoded `mL` strings.
2. Expose the current child's preferred feed volume unit through `SummaryViewModel` so summary screens and advanced summary views can respect the saved setting.
3. Update today summary, trends summary, advanced summary, bottle chart labels, and timeline day-grid bottle titles to display bottle amounts in the preferred unit while keeping calculations stored in milliliters.
4. Add or update tests that cover bottle amount formatting in milliliters and ounces for summary and timeline presentations.
5. Create a focused branch from the current HEAD, verify the change with relevant tests/build checks, and raise a PR into `main`.

- [x] Complete
