# 033 AppModel UseCase Boundary

## Goal
Break `AppModel` into a thinner app coordinator that owns in-memory session, navigation, and feature routing while moving business and application logic behind plain Swift use cases that feature packages can execute directly.

## Why
- `AppModel` currently mixes app coordination, read-model loading, feature policy, screen-state derivation, sync orchestration, and transient UI state.
- The write path is already partly use-case driven, but the read path and several decision paths still live directly in `AppModel`.
- Pulling non-UI logic behind use cases should make features easier to test, reduce merge pressure on one file, and clarify which logic belongs to Domain versus presentation.

## Socratic Framing
1. What should `AppModel` still own after the refactor?
   App-level in-memory state and coordination: route, selected child/workspace, navigation reset tokens, transient banners, share sheet presentation, import/export flow state, and async task orchestration.
2. What logic should not stay in `AppModel`?
   Any logic that answers business or application questions such as "who is the active user?", "which child should be shown?", "what data belongs in the current child workspace?", "what actions are allowed?", or "what suggestions can be derived from event history?"
3. What logic should not be forced into Domain?
   SwiftUI-specific view state and layout details. `ChildProfileScreenState`, `TimelineEventBlockViewState`, sheet tokens, and banner presentation are presentation concerns even if they are plain Swift types.
4. If a feature needs logic, what should it execute?
   A use case that returns domain entities or feature-agnostic snapshots. The feature package can then map that result into screen state locally.
5. What is the smallest safe first slice?
   Extract the read-side loading path before splitting write coordinators. That gives the team a cleaner seam without forcing view rewrites up front.

## Proposed Boundaries
### Keep in `AppModel`
1. Route changes and navigation resets.
2. Currently selected child and workspace tab.
3. Presentation-only state such as banners, sheet requests, import/export flow state, and share sheet state.
4. Launching async sync work and deciding when to refresh in-memory state.

### Move behind use cases
1. Loading the local app session and deciding the initial route.
2. Loading the active child workspace snapshot from repositories and sync state.
3. Deriving sleep start suggestions from event history.
4. Child deletion follow-up decisions such as next selected child.
5. Import/export preparation steps that are business or data-flow logic rather than UI state transitions.

### Keep as feature mappers or calculators
1. Mapping workspace snapshots into `ChildProfileScreenState`.
2. Mapping events into `HomeScreenState`, `EventHistoryScreenState`, and `SummaryScreenState`.
3. Timeline block layout and other view-layout shaping, unless a later pass proves a reusable domain abstraction is needed.

## Plan
1. Inventory `AppModel` methods into three buckets: app coordination, business/application logic, and presentation mapping.
2. Introduce a `LoadAppSessionUseCase` in `BabyTrackerDomain` that loads the local user, active children, archived children, persisted child selection, and the initial route decision.
3. Introduce a `LoadChildWorkspaceUseCase` in `BabyTrackerDomain` that loads the selected child, memberships, users, visible events, active sleep, pending sync counts, and pending invites into a feature-agnostic snapshot.
4. Introduce a `BuildSleepStartSuggestionsUseCase` in `BabyTrackerDomain` so this derivation no longer lives inside `AppModel`.
5. Refactor `AppModel.refresh(selecting:)` to delegate data loading and route decisions to the new use cases, keeping only in-memory state updates, sync triggering, and presentation error handling.
6. Move screen-state assembly out of `AppModel` into focused feature mappers or calculators, keeping `ChildProfileScreenState` construction in `BabyTrackerFeature` rather than Domain.
7. Reassess timeline logic after the read-path extraction. Keep block layout in Feature unless there is a clear non-UI use case for moving more of it.
8. Add tests at the new seams:
   `LoadAppSessionUseCase` tests for route and selection decisions.
   `LoadChildWorkspaceUseCase` tests for membership, event, and pending-change assembly.
   Feature mapper tests for `ChildProfileScreenState` and timeline/home/history shaping.
9. After the read path is stable, consider a second pass that splits `AppModel` into smaller coordinators only where doing so reduces coupling rather than creating wrapper types.

## Acceptance Criteria
1. `AppModel` no longer performs repository-heavy read assembly directly.
2. Initial route and selected-child decisions are covered by domain-level tests.
3. Feature packages can execute use cases to obtain workspace data without depending on app-target-only code.
4. Presentation-only mapping remains outside Domain.
5. `AppModel` remains the owner of navigation and in-memory UI state, not a new god object made of smaller wrappers.

## Out of Scope
1. Rewriting every existing write action if it already delegates cleanly to a use case.
2. Moving SwiftUI view state types into Domain.
3. Splitting `AppModel` into multiple observable objects in the same pass unless a slice clearly pays for itself.
4. Changing sync engine responsibilities beyond what is required to supply data to the new use cases.

## Notes
- `BabyTrackerFeature` currently depends on `BabyTrackerPersistence` directly. If repository protocols are not already domain-owned, that dependency direction should be reviewed during this work so features can depend on domain-defined abstractions instead of persistence-defined ones.
- `BuildTimelineStripDatasetUseCase` already shows the intended pattern: plain Swift logic, no SwiftUI dependency, and a result that the feature layer can map for display.
- The first milestone should optimize for a safe seam around `refresh(selecting:)`, because that method currently centralizes most of the mixed responsibilities.

- [ ] Complete
