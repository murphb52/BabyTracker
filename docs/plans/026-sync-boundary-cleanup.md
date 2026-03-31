# 026 Sync Boundary Cleanup

## Goal

Confine CloudKit to `BabyTrackerSync` and app-level Apple framework bridges so that:

- `BabyTrackerDomain` contains business concepts only
- `BabyTrackerPersistence` does not expose `CK*` types in its public APIs
- `BabyTrackerFeature` does not depend on CloudKit-shaped sync types
- replacing the sync backend later does not require touching unrelated packages

## Current Boundary Leaks

1. Domain contains CloudKit-specific state and language.
   - `UserIdentity` stores `cloudKitUserRecordName`.
   - cleanup use cases describe CloudKit operations directly in their public intent and documentation.

2. Persistence exposes CloudKit types in public contracts.
   - `CloudKitChildContext` uses `CKRecordZone.ID` and `CKDatabase.Scope`.
   - `SyncAnchor` uses `CKDatabase.Scope` and `CKRecordZone.ID`.
   - `CloudKitRecordMetadataRepository` uses `CKRecord.ID` and `CKDatabase.Scope`.

3. Feature depends on CloudKit-shaped sync APIs.
   - `CloudKitSyncControlling` returns `CloudKitPendingInvite` and `CloudKitSharePresentation`.
   - `ShareSheetState` stores `CloudKitSharePresentation`.
   - CloudKit share presentation is currently part of the feature package boundary.

4. Package dependencies are still wider than intended.
   - `BabyTrackerFeature` depends on `BabyTrackerPersistence` and `BabyTrackerSync`.
   - `BabyTrackerSync` imports `BabyTrackerPersistence` to reach CloudKit-specific repository refinements.

## Target Architecture

- `BabyTrackerDomain`
  - domain entities, value types, use cases, and repository abstractions
  - no CloudKit naming, IDs, scopes, or Apple framework types

- `BabyTrackerPersistence`
  - SwiftData-backed local storage
  - public APIs expose domain models and provider-neutral sync storage models only
  - no public `CK*` types

- `BabyTrackerSync`
  - owns CloudKit-specific mapping, client code, sync orchestration, and share preparation
  - converts between CloudKit records and neutral sync storage DTOs
  - exposes provider-neutral protocols and DTOs upward

- App target
  - composition root
  - CloudKit share acceptance bridge, scene/app delegate hooks, and UIKit share presentation
  - wires feature layer to CloudKit-backed sync implementations

## Planned Changes

### 1. Remove CloudKit-specific state from Domain

- remove `cloudKitUserRecordName` from `UserIdentity`
- move remote identity linking into sync-owned storage instead of the domain entity
- rename cleanup intent wording to express ownership and sharing semantics, not CloudKit operations
- keep domain outputs at the level of:
  - owned child
  - shared child
  - owner action
  - caregiver action

### 2. Replace CloudKit-shaped persistence contracts with neutral sync storage contracts

- replace `CloudKitChildContext` with a neutral sync context model using strings and app-defined enums
- replace `SyncAnchor` with a neutral anchor model that does not expose `CKDatabase.Scope` or `CKRecordZone.ID`
- replace `CloudKitRecordMetadataRepository` with a sync-owned metadata store keyed by existing app record references
- rename CloudKit-specific repository refinements so they describe sync storage responsibilities, not the backend

### 3. Replace CloudKit-shaped feature APIs with neutral sync APIs

- replace `CloudKitSyncControlling` with `SyncControlling`
- replace `CloudKitPendingInvite` with a neutral pending invite DTO and app-defined acceptance status enum
- replace `CloudKitSharePresentation` with a neutral share-preparation result that does not expose `CKShare` or `CKContainer`
- keep `SyncStatusSummary` as the shared UI-facing sync status type

### 4. Move CloudKit share presentation out of Feature

- remove `UICloudSharingController` presentation concerns from `BabyTrackerFeature`
- keep share sheet presentation in the app target or a clearly CloudKit-specific adapter layer
- let the feature layer emit:
  - a share action request
  - a provider-neutral share payload
- let the app target translate that into the actual CloudKit share sheet

### 5. Tighten package dependencies

- target dependency direction:
  - `Feature -> Domain`
  - `Persistence -> Domain`
  - `Sync -> Domain` plus sync-owned storage abstractions
  - `App -> Feature + Persistence + Sync`
- remove `Feature -> Persistence`
- remove `Feature -> Sync`
- keep CloudKit imports confined to `BabyTrackerSync` implementation files and app-level bridges

## Validation

1. Domain compiles and tests pass with no CloudKit references in public types.
2. Persistence public APIs expose no `CK*` types.
3. Feature tests can fake sync behavior without constructing CloudKit objects.
4. Sync retains CloudKit mapper and engine coverage.
5. App share acceptance and share sheet flows continue to work through app-level bridges.

## Notes

- This plan keeps the current manual sync architecture.
- This plan does not introduce a generalized Firebase-ready backend abstraction.
- The goal is cleaner boundaries now, not a full provider swap in this pass.

- [ ] Complete
