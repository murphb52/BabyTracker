# BabyTracker Refactor Progress

Tracking document for the clean architecture refactor plan.
Source plan: `docs/babytracker-clean-architecture-plan.md`

## Steps

- [x] **Step 1 — Phase 1:** Remove Stage typealiases (`Stage1AppModel`, `Stage1Route`), rename `Stage1/` folder and `Stage1ErrorBannerView`
- [ ] **Step 2 — Phase 2:** Extract `TimelineModel` from `AppModel`
- [ ] **Step 3 — Phase 2:** Extract `SharingModel` from `AppModel`
- [ ] **Step 4 — Phase 2:** Extract `ChildContextModel` + `EventLoggingModel` from `AppModel`
- [x] **Step 5 — Phase 3:** Introduce UseCase layer in BabyTrackerDomain (17 use cases)
- [x] **Step 6 — Phase 4:** Split `ChildProfileRepository` into focused protocols + implementations
- [x] **Step 7 — Phase 5 (protocol split):** Move repository protocols to Domain; CloudKit refinements remain in Persistence
- [ ] **Step 8 — Phase 6:** Audit Sync for CloudKit leakage into Domain
- [ ] **Step 9 — Phase 7:** Simplify `AppContainer`, separate preview/seeding concerns

## Notes

**Step 5:** Introduced `UseCase` protocol (marked `@MainActor`) in `BabyTrackerDomain/UseCases/`. Created 17 concrete UseCases covering all domain actions: `CreateLocalUser`, `CreateChild`, `UpdateCurrentChild`, `ArchiveCurrentChild`, `RestoreChild`, `RemoveCaregiver`, `LogBreastFeed`, `LogBottleFeed`, `LogNappy`, `StartSleep`, `EndSleep`, `UpdateBreastFeed`, `UpdateBottleFeed`, `UpdateNappy`, `UpdateSleep`, `DeleteEvent`, `RestoreDeletedEvent`. `AppModel` now calls UseCases from its `perform {}` wrappers. `AppModel.restoreDeletedEvent` private helper removed (logic is in `RestoreDeletedEventUseCase`). Actions that depend on `CloudKitSyncEngine` (`leaveChildShare`, `presentShareSheet`) remain in `AppModel`.

**Step 6:** Split into `SwiftDataChildRepository`, `SwiftDataUserIdentityRepository`, `SwiftDataMembershipRepository`, `UserDefaultsChildSelectionStore`. `AppModel` and `CloudKitSyncEngine` updated to inject the focused protocols directly. `SwiftDataChildProfileRepository` deleted. `purgeChildData` no longer clears selected child ID — callers own that responsibility (`AppModel.leaveChildShare` handles it explicitly).

**Step 7 (protocol split):** Core repository protocols (`ChildRepository`, `EventRepository`, `UserIdentityRepository`, `MembershipRepository`, `ChildSelectionStore`) moved to `BabyTrackerDomain/Repositories/`. CloudKit-specific methods remain in `BabyTrackerPersistence` as refinement protocols: `CloudKitChildRepository`, `CloudKitUserIdentityRepository`, `CloudKitMembershipRepository`. `CloudKitSyncEngine` updated to use `CloudKit*` refinements. `SwiftData*Repository` implementations updated to conform to `CloudKit*` protocols.
