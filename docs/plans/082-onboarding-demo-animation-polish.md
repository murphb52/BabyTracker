# 082 — Onboarding Demo Animation Polish

## Goal

Tighten the onboarding demo pacing so each screen reads more clearly:
- add weekday x-axis labels to the timeline demo
- delay the timeline legend until the block animation fully finishes
- overlap the second chart draw with the first chart draw
- animate the Quick Log card in before its buttons pop in

## Approach

1. Update `OnboardingTimelineDemoView` to render weekday labels (`M T W T F`) under the five columns and treat that label row as part of the chart presentation.
2. Adjust the timeline animation sequence so the legend begins only after the last block animation has completed, with a small extra pause before the stagger starts.
3. Update `OnboardingChartsDemoView` so the bottle chart starts drawing halfway through the sleep chart animation instead of waiting for the first line to finish.
4. Update `OnboardingQuickLogDemoView` so the full Quick Log card enters with the same card spring used on the charts page, then start the button stagger only after the card has settled.

## Notes

- This is a focused polish pass only; no onboarding flow logic changes are intended.
- Existing previews remain sufficient because these changes only adjust presentation and animation timing.

## Verification

1. Open onboarding step "Log in seconds" and confirm the card slides/fades in before the four buttons start popping in.
2. Open onboarding step "See the whole picture" and confirm weekday labels appear under the five columns.
3. Confirm the timeline legend does not begin animating until the last timeline blocks have fully finished animating.
4. Open onboarding step "Spot the patterns" and confirm the second chart line starts drawing while the first chart line is still animating.

- [x] Complete
