# 049 - Domain boundary for latest event selection

## Goal
Move event-selection logic that does not require presentation formatting into the domain layer so it can be reused by pure Swift use cases and tested independently of UI state types.

## Approach
1. Add domain use cases for selecting the latest event, latest nappy event, and latest sleep summary.
2. Update feature-layer summary calculators to delegate event-selection logic to the domain use cases while keeping presentation formatting in feature.
3. Add domain tests that cover the new selection use cases.

- [x] Complete
