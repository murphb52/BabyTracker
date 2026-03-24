# BabyTracker Refactor Progress

Tracking document for the clean architecture refactor plan.
Source plan: `docs/babytracker-clean-architecture-plan.md`

## Steps

- [x] **Step 1 — Phase 1:** Remove Stage typealiases (`Stage1AppModel`, `Stage1Route`), rename `Stage1/` folder and `Stage1ErrorBannerView`
- [ ] **Step 2 — Phase 2:** Extract `TimelineModel` from `AppModel`
- [ ] **Step 3 — Phase 2:** Extract `SharingModel` from `AppModel`
- [ ] **Step 4 — Phase 2:** Extract `ChildContextModel` + `EventLoggingModel` from `AppModel`
- [ ] **Step 5 — Phase 3:** Introduce first use cases (`SelectChild`, `LoadTimeline`)
- [x] **Step 6 — Phase 4:** Split `ChildProfileRepository` into focused protocols + implementations
- [ ] **Step 7 — Phase 5:** Move repository protocols to Domain, break `Feature → Persistence` dependency
- [ ] **Step 8 — Phase 6:** Audit Sync for CloudKit leakage into Domain
- [ ] **Step 9 — Phase 7:** Simplify `AppContainer`, separate preview/seeding concerns

## Notes

**Step 6:** Split into `SwiftDataChildRepository`, `SwiftDataUserIdentityRepository`, `SwiftDataMembershipRepository`, `UserDefaultsChildSelectionStore`. `AppModel` and `CloudKitSyncEngine` updated to inject the focused protocols directly. `SwiftDataChildProfileRepository` deleted. `purgeChildData` no longer clears selected child ID — callers own that responsibility (`AppModel.leaveChildShare` handles it explicitly).
