# 068 Share acceptance loading view refinements

## Goal
Refine `ShareAcceptanceLoadingView` so its SF Symbol animation behaves consistently with onboarding, its status content sizes cleanly, and the loading scene remains visually stable.

## Plan
1. Keep the loading symbol visually centered and let the status message wrap without clipping.
2. Reuse the onboarding animated SF Symbol scene implementation directly instead of maintaining a separate loading-view-specific animation.
3. Align the acceptance screen layout more closely with the onboarding step layout so the shared animated scene sits in a stable parent container.
4. Replace the problematic third symbol with a clearer sync-related SF Symbol.
5. Verify the project still builds cleanly after the final view and plan cleanup.

- [x] Complete
