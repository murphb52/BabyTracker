# 049 Domain Today Summary Boundary

## Goal
Move today summary calculation logic out of the feature layer and into the domain layer so the core metrics are pure Swift domain code with a clear boundary.

## Approach
1. Add a domain `TodaySummary` model that represents calculated summary metrics without presentation concerns.
2. Add a domain `BuildTodaySummaryUseCase` that computes today summary values from domain events.
3. Update feature `TodaySummaryCalculator` to delegate to the domain use case and map domain output to `TodaySummaryData`.
4. Add domain-level tests for the new use case and keep existing feature tests green.

## Notes
- Keep logic behavior equivalent to avoid UI behavior changes.
- Keep `Calendar` and `Date` injectable so tests remain deterministic.

- [x] Complete
