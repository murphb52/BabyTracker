# 002 Stage 0 Foundation, Spec Alignment, and Delivery Setup

## Summary

This plan converts the repo from the default Xcode template into a small iOS-only foundation that Stage 1 can build on directly.

The work in this stage:

1. Reconcile the MVP data model across the PRD and technical design spec.
2. Replace the template app shell with a simple composition root.
3. Introduce the first local Swift packages for domain, persistence, sync, and feature scaffolding.
4. Move important Xcode settings into checked-in xcconfig files.
5. Add local validation and CI coverage for simulator tests.
6. Record the Apple Developer and CloudKit setup that must be completed alongside the repo changes.

## Locked Decisions

1. Platform scope is iPhone and iPad only.
2. SwiftData remains the local persistence direction.
3. CloudKit remains the sync direction.
4. `milkType` is optional for bottle feeds in the MVP.
5. The MVP nappy schema is:
   - `type: NappyType`
   - `intensity: NappyIntensity?`
   - `pooColor: PooColor?`
   - `pooColor` is valid only for `.poo` and `.mixed`
6. `PooConsistency` is out of scope for the MVP.
7. The first local packages are:
   - `BabyTrackerDomain`
   - `BabyTrackerPersistence`
   - `BabyTrackerSync`
   - `BabyTrackerFeature`

## Tasks

1. Update product documentation.
   - Align the PRD and the technical design spec with the same typed MVP schema.
   - Add typed definitions for `Child`, `UserIdentity`, and `Membership`.
   - Document the staged package rollout.

2. Replace the template app shell.
   - Remove the template `Item` model and list UI.
   - Add `AppContainer`, `AppRootView`, and a new `BabyTrackerApp` entry point.
   - Show a clear empty foundation screen that points to Stage 1 work.

3. Introduce the first local packages.
   - Add `BabyTrackerDomain` with the initial shared types and validation rules.
   - Add `BabyTrackerPersistence` with a small Stage 1-facing repository seam.
   - Add `BabyTrackerSync` with the CloudKit container configuration surface.
   - Add `BabyTrackerFeature` with the root app state used by the app shell.

4. Clean up Xcode project configuration.
   - Move explicit target and configuration settings into checked-in xcconfig files.
   - Keep the app iOS-only.
   - Normalize bundle identifiers.
   - Keep automatic signing enabled without committing a personal team ID.

5. Add validation automation.
   - Add `scripts/validate.sh`.
   - Add a GitHub Actions workflow that runs the same validation command.

6. Wire CloudKit capability scaffolding.
   - Point entitlements at `iCloud.com.adappt.BabyTracker`.
   - Keep full CloudKit schema work for Stage 2.
   - Keep Live Activities capability work for Stage 5.

7. Replace template tests.
   - Add unit tests for membership types, bottle-feed optional `milkType`, and nappy validation.
   - Add a UI smoke test for the new foundation screen.

## Exit Criteria

- The running app no longer shows the template item list.
- The repo has a clear composition root and package layout for Stage 1.
- The PRD and technical design spec no longer disagree on the MVP model.
- Simulator tests run through `scripts/validate.sh`.
- The repo includes documented hook installation and CI validation.
- CloudKit container configuration is documented and reflected in entitlements.

## Development Notes

### Local Validation

Run:

```sh
./scripts/validate.sh
```

### Apple Developer and CloudKit Setup

1. Create or confirm the App ID `com.adappt.BabyTracker`.
2. Create the iCloud container `iCloud.com.adappt.BabyTracker`.
3. Enable iCloud and CloudKit for the app target in Apple Developer and Xcode.
4. Confirm the app target signs with a valid development team locally.
5. Leave CloudKit schema records and Live Activities capability work for later stages.

- [ ] Complete
