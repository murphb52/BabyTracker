# 106 - Quick Log Two-Column Grid

## Summary
Keep Home Quick Log buttons in a consistent two-column layout, even when the enabled event count is odd. The last button should occupy a single grid cell instead of stretching across the full row.

## Plan
1. Update `ChildHomeView` to use a fixed two-column grid for Quick Log buttons.
2. Remove the row-building layout logic that currently allows an odd trailing button to become full width.
3. Verify the Home preview still renders the Quick Log section correctly with the updated layout.

## Notes
- This is a small UI polish change, so no separate GitHub issue is needed.

- [x] Complete
