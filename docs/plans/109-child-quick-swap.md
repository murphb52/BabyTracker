# 109 Child Quick Swap

## Goal

Make it faster to move between children when more than one active child is available, using a GitHub-style stacked avatar affordance in the top-right home toolbar.

## Approach

1. Show a single child avatar for one active child and a compact stacked avatar for multiple active children.
2. Let a downward swipe on the stacked avatar switch to the next active child without moving away from the current workspace tab.
3. Let tapping the avatar open a menu with clear child actions:
   - view a child profile
   - set a child active without changing tabs
4. Add a first-run TipKit tip when multiple children are available so users learn the swipe gesture.
5. Keep the selection logic in `AppModel` simple by allowing callers to choose whether a child switch should navigate to the profile tab.
6. Add focused model tests for quick swaps that should stay on the current tab.

## Completion

- [x] Complete
