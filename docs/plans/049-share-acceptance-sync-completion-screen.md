# 049 Share acceptance sync completion screen

## Goal
Build a dedicated share-acceptance screen that clearly tells the caregiver they accepted an invitation for a child, shows prominent sync-in-progress feedback while data downloads, and then presents a Continue action that takes them into the child profile.

## Approach
1. Extend share acceptance loading state to model two explicit phases: syncing and ready-to-continue, while carrying the child name for user-facing copy.
2. Redesign the share acceptance screen to match onboarding visual style with SF Symbols, a gradient icon scene, clear sync messaging, and a prominent ProgressView while syncing.
3. Add a completion phase UI with a Continue button that dismisses the overlay and reveals the child profile route.
4. Update app model flow so acceptance completion refreshes profile data, transitions state to ready-to-continue, and exposes a dedicated dismiss action.
5. Update and add AppModel tests for syncing state, completion state, and continue-dismiss behavior.

- [x] Complete
