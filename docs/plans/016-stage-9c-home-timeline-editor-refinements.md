# 016 Stage 9C: Home, Timeline, and Editor Refinements

## Summary

Apply a focused polish pass to the child workspace:

1. Remove Home recent activity.
2. Always show the Timeline `Today` button.
3. Make the Timeline week strip include Sunday.
4. Add quick duration presets to breast feeds.
5. Add 10 mL quick amount presets up to 70 mL for bottle feeds.
6. Fix sleep defaults so a newly logged sleep does not appear to be in the future.
7. Make timeline blocks always show an icon plus meaningful text, with sleep using the extra space for more detail.

## Implementation

1. Remove the recent activity section from Home and simplify the related view wiring.
2. Keep the Timeline `Today` control visible at all times.
3. Derive Timeline visible days from a Sunday-start week.
4. Add explicit preset buttons to the breast feed editor.
5. Add explicit preset buttons to the bottle feed editor.
6. Clamp sleep editor defaults and picker ranges so sleep events cannot default into the future.
7. Update timeline compact labels and block rendering so bottle and nappy events show concise text with icons.

- [x] Complete
