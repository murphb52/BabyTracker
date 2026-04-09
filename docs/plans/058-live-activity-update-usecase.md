# 058 - Live activity update use case

## Goal
Introduce a dedicated use case for synchronizing live activity state so AppModel can trigger updates frequently without duplicating snapshot-building logic.

## Plan
1. Add a `SyncFeedLiveActivityUseCase` in `BabyTrackerFeature` that accepts the current child, visible events, active sleep, the preference flag, and the live activity manager.
2. Replace direct `BuildFeedLiveActivitySnapshotUseCase` + manager calls in `AppModel` with the new use case.
3. Add an explicit AppModel method for re-triggering live activity synchronization from current in-memory state.
4. Add tests that verify the use case behavior for enabled and disabled states and missing child context.

- [x] Complete
