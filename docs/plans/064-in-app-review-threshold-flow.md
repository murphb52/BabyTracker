# 064 In-app review threshold flow

## Goal
Add an in-app App Store review prompt flow that triggers only after the user has logged a meaningful number of events, while keeping decision logic in the domain layer and Apple framework usage at upper layers.

## Plan
1. Add a domain boundary for review prompt tracking and review request dispatch so the domain can decide *when* to prompt without depending on StoreKit.
2. Add a domain use case that increments a persisted event-log counter and returns whether a review prompt should be requested at configured thresholds.
3. Integrate the use case into `AppModel` after successful event logging actions so the flow runs in one place with minimal coupling.
4. Implement upper-layer concrete adapters:
   - UserDefaults-backed review prompt state store.
   - StoreKit-backed review requester using Apple in-app review APIs.
5. Wire new adapters in `AppContainer` for live app usage, and keep preview/testing defaults no-op safe.
6. Add focused domain tests for threshold behavior and one-time prompting semantics.
7. Run relevant test targets and update this plan to complete when implementation and verification are done.

- [x] Complete
