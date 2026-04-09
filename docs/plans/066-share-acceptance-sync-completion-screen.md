# 066 Share acceptance sync completion screen

## Goal
Show a dedicated post-invitation screen that clearly communicates two phases:
1. the invitation was accepted and we are syncing potentially large child data, and
2. syncing finished and the user can continue to the child profile.

## Plan
1. Extend share acceptance state to represent explicit phases (`syncing` and `completed`) and carry the accepted child name for user-facing copy.
2. Update `AppModel` share-acceptance flow so:
   - accepting starts in `syncing`,
   - completion refreshes app data and moves to `completed`,
   - tapping continue clears the share acceptance screen and lands in the child profile route.
3. Wire `ShareAcceptanceHandler` and `AppContainer` so the child name from share metadata is passed into the app flow.
4. Redesign `ShareAcceptanceLoadingView` with onboarding-like SF Symbol presentation, prominent loading affordances, and a completion CTA.
5. Add/update tests for the phase transition and continue behavior.

- [x] Complete
