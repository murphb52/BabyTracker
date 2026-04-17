# 082 Summary Today Date Picker Layout Fix

## Goal

Fix the squashed day picker shown from the Today tab on the Summary screen so the date picker presents at a readable, usable size.

## Approach

1. Inspect the current Today tab date picker presentation in `SummaryScreenView`.
2. Update the popover content to use an explicit container size that suits the graphical date picker on iPhone.
3. Run the relevant unit test plan to confirm the screen still builds after the layout change.

Tiny UI polish only, so no GitHub issue is needed for this change.

- [x] Complete
