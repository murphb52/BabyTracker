# 004 Stage 2: Local Data Model and CloudKit Sync

## Summary

Implement Stage 2 as a local-first data foundation plus real CloudKit sharing. Keep SwiftData as the single local source of truth, add an explicit sync layer in `BabyTrackerSync`, and replace the temporary Stage 1 caregiver flow with `CKShare`-based invite and acceptance behavior.

## Locked Decisions

1. Stage 2 includes real CloudKit sharing now, not just sync scaffolding.
2. Sync status stays minimal in Stage 2 with a lightweight profile-level banner.
3. SwiftData remains local source of truth. CloudKit sync is explicit and custom.
4. UUID-based identifiers remain the canonical local IDs.
5. Stage 1 placeholder caregiver rows are migration-only scaffolding and can be removed.
6. `milkType` remains optional and the current nappy schema is unchanged.

## Work Items

1. Add typed event and sync domain models.
2. Extend SwiftData storage with event and sync metadata models.
3. Add event and sync repositories plus Stage 1 data migration helpers.
4. Add CloudKit mapping and a sync engine.
5. Replace fake caregiver invite activation with CloudKit share flows.
6. Add minimal sync state UI on the child profile screen.
7. Expand unit and UI coverage for Stage 2 behaviors.

## Exit Criteria

1. Typed event models exist in the domain layer.
2. Local persistence can store events and sync metadata.
3. CloudKit sync surfaces compile and are wired into the app.
4. Stage 1 local-only caregiver activation scaffolding is removed.
5. Profile UI shows minimal sync state and a CloudKit share action.
6. `./scripts/validate.sh` passes.

- [x] Complete
