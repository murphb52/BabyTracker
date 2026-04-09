# App Submission Review

Date: 2026-04-09

This document summarizes the current release-readiness review for Baby Tracker and grades the work from strictly necessary down to optional cleanup.

## Validation Summary

- `xcodebuild build -project "Baby Tracker.xcodeproj" -scheme "Baby Tracker" -configuration Release -destination "generic/platform=iOS Simulator"` succeeded.
- `xcodebuild test -project "Baby Tracker.xcodeproj" -scheme "Baby Tracker" -testPlan "UnitTests" -parallel-testing-enabled NO -destination "platform=iOS Simulator,OS=26.2,name=iPhone 17"` succeeded.
- Unit test coverage is strong for domain, persistence, sync, and feature logic.
- This review did not include a signed archive upload, App Store Connect metadata entry, or full physical-device TestFlight validation.

## Strictly Necessary Before Release

These items should be treated as release blockers.

### 1. Remove internal milestone and placeholder copy from the shipping UI

- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/InviteCaregiverSheetView.swift:17` still says: "This Stage 1 flow creates a local placeholder caregiver. Real CloudKit sharing arrives in Stage 2."
- If this screen is reachable in production, that copy makes the app look unfinished and internally staged.
- Replace it with user-facing copy or remove the explanatory section entirely.

### 2. Complete Apple-side CloudKit and distribution setup

- The repo already documents the required manual work in `docs/testflight-cloudkit-manual-setup.md`.
- Confirm all of the following before submission:
- The app ID `com.adappt.BabyTracker` exists.
- The iCloud container `iCloud.com.adappt.BabyTracker` exists.
- iCloud and CloudKit are enabled for the app ID.
- Push notifications are enabled for the app ID.
- Development and distribution provisioning profiles were regenerated after capability changes.
- The CloudKit schema was deployed to Production.
- Production contains the record types and indexes the app expects.

### 3. Verify distribution signing and entitlements

- The checked-in entitlements are development-flavored in `Baby Tracker/Baby Tracker.entitlements`.
- That is normal for local development, but the release archive must be signed with the correct production distribution profile and resolved entitlements.
- Before submission, archive once and inspect the signed app entitlements in Organizer or the exported archive to confirm the final signing output is correct.

### 4. Add a privacy manifest and align App Store privacy answers

- No `PrivacyInfo.xcprivacy` file is present in the repo.
- The app uses APIs that should be accounted for in release compliance work, including:
- `UserDefaults`
- file export and temporary file writes
- pasteboard copy in logs
- photo picking
- notifications
- Add the privacy manifest and make sure App Store Connect privacy disclosures match actual behavior.

### 5. Run a real TestFlight pass on physical devices

- This app depends heavily on iCloud, CloudKit sharing, push behavior, and Live Activities.
- Simulator validation is not enough.
- At minimum, test:
- fresh install onboarding
- child creation and editing
- feed, sleep, and nappy logging
- owner and caregiver sharing across two Apple IDs
- share acceptance
- sync back-and-forth after both sides create events
- notification permission flow
- Live Activities behavior on a real device

## High Priority

These are not guaranteed blockers, but they are worth addressing before submission.

### 1. Remove release-build warnings

The release build succeeds, but it still emits warnings:

- sendability warnings in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildCreationView.swift`
- sendability warnings in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildEditSheetView.swift`
- unused-value warnings in `AppModel.swift`
- an unused local in `EventFilterView.swift`

These are not catastrophic, but shipping with known warnings is avoidable and makes release quality harder to trust.

### 2. Remove raw `print` diagnostics from release code paths

There are still direct debug prints in app and sync flows, for example:

- `Baby Tracker/App/CloudKitShareAppDelegate.swift`
- `Baby Tracker/App/CloudKitShareSceneDelegate.swift`
- `Baby Tracker/App/CloudKitShareAcceptanceBridge.swift`
- `Packages/BabyTrackerSync/Sources/BabyTrackerSync/CloudKitSyncEngine.swift`

Prefer `Logger` and `AppLogger` only, or gate noisy diagnostics out of release.

### 3. Prepare App Review notes

App Review will likely benefit from a short note explaining:

- the app uses iCloud and CloudKit for sync and sharing
- sharing requires iCloud to be signed in
- multi-user sharing is best demonstrated with two physical devices and two Apple IDs
- notification behavior is tied to caregiver sync updates

This reduces the chance of a rejection caused by incomplete reviewer setup.

## Medium Priority

These items improve polish and lower support risk.

### 1. Decide whether internal support surfaces should be public in release

These screens are currently exposed in settings:

- Logs in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/AppSettingsView.swift`
- Advanced Diagnostics in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildProfileSyncView.swift`
- Erase Everything in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/AppSettingsView.swift`

None of these are automatically wrong for release, but they should be intentional product decisions rather than leftover engineering affordances.

### 2. Review user-facing wording for destructive actions

- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/NukeAllDataView.swift` is clear and strongly warns the user.
- Even so, a full-account wipe is a severe action.
- Confirm that the naming, placement, and confirmation flow match the product you want to ship publicly.

### 3. Confirm App Store Connect metadata is ready

Before submission, make sure App Store Connect is complete:

- app description
- keywords
- support URL
- privacy policy URL
- age rating
- screenshots for required device classes
- release notes

This review did not inspect App Store Connect metadata.

## Nice To Have

These can wait if the required release work is complete.

### 1. Improve UI regression coverage

- The unit test suite passed with 138 tests.
- UI test coverage is not complete, and there are skipped UI tests in `Baby TrackerUITests/Baby_TrackerUITests.swift`.
- Reinstating those tests would reduce manual release verification work.

### 2. Trim or refine end-user diagnostics

- The Logs screen can be useful for support, but it may also expose internal categories and language that normal users do not need.
- If you keep it, consider making the presentation more support-oriented and less engineering-oriented.

### 3. Archive and inspect the final binary earlier in the process

- The local review used a Release simulator build, not a signed archive.
- Running a full archive and inspecting the result before final submission will catch signing or packaging surprises earlier.

## Recommended Release Order

1. Remove internal placeholder copy.
2. Add the privacy manifest and verify App Store Connect privacy disclosures.
3. Confirm Apple Developer capabilities, provisioning, and CloudKit Production schema deployment.
4. Archive a release build and inspect final entitlements.
5. Run the physical-device TestFlight validation pass.
6. Clean warnings and remove raw diagnostic prints.
7. Decide whether Logs, Advanced Diagnostics, and Erase Everything should stay exposed.
