# 055 - Show hours for long durations

## Goal
Update user-facing duration text so displays stop showing large raw minute counts and switch to hour-aware formatting once a duration reaches one hour.

## Approach
1. Audit the feature layer for places that render durations as raw minutes.
2. Add a shared duration formatter in `BabyTrackerFeature` so event cards, summaries, timeline items, filters, and editors all use the same hour-aware formatting rules.
3. Keep short durations readable and preserve existing non-duration copy where possible.
4. Update tests that assert duration text so hour-based output is covered explicitly.
5. Run the relevant test target and mark the plan complete if the suite passes.

## Verification
1. Run the relevant `Baby TrackerTests` cases for duration formatting.

- [x] Complete
