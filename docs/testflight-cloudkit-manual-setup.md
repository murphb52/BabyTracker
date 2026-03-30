# TestFlight and CloudKit Manual Setup

This document lists the Apple-side steps that must be completed outside the repo before CloudKit sync and CloudKit sharing work reliably in TestFlight and Production.

## 1. Apple Developer Configuration

1. Confirm the app identifier exists as `com.adappt.BabyTracker`.
2. Confirm the iCloud container exists as `iCloud.com.adappt.BabyTracker`.
3. Enable the `iCloud` capability for the app ID.
4. Enable `CloudKit` under the iCloud capability for the app ID.
5. Regenerate any development and distribution provisioning profiles after enabling or changing capabilities.

## 2. Xcode Signing and Capabilities

1. Open the `Baby Tracker` target in Xcode.
2. Set the correct development team for the app target and any related extension targets.
3. In `Signing & Capabilities`, confirm `iCloud` is enabled.
4. Confirm the selected container is `iCloud.com.adappt.BabyTracker`.
5. Confirm the app and extension use valid signing identities for Debug and Release builds.

## 3. CloudKit Dashboard

1. Open CloudKit Dashboard for `iCloud.com.adappt.BabyTracker`.
2. Verify the Development schema contains the record types the app uses:
   `Child`, `Membership`, `UserIdentity`, `BreastFeedEvent`, `BottleFeedEvent`, `SleepEvent`, `NappyEvent`.
3. Verify the schema and indexes are correct in Development before promoting anything.
4. Deploy the CloudKit schema to Production.
5. Re-check that the Production environment now contains the same record types.

If the schema is not deployed to Production, CloudKit sharing and record saves may fail in TestFlight even if they worked in local development.

## 4. TestFlight Distribution

1. Create an archive from the Release configuration.
2. Upload the build to App Store Connect.
3. Add the build to a TestFlight group.
4. Wait for Beta App Review and processing to complete.
5. Install the TestFlight build on physical devices.

## 5. Real-World Sharing Requirements

1. Test sharing on physical devices, not just the simulator.
2. Sign into iCloud on both devices.
3. Use two different Apple IDs when testing owner and caregiver flows.
4. Make sure both devices have iCloud Drive enabled.
5. Accept the share invitation on the recipient device and reopen the app if needed.

If the app is not signed into iCloud, sync will fail and sharing will be unavailable.

## 6. Push and Background Delivery

1. Confirm push notifications are enabled for the app ID.
2. Confirm the provisioning profiles include push entitlements.
3. Allow notifications on test devices if you want to verify remote sync nudges and background behavior.

## 7. Recommended First TestFlight Validation Pass

1. Install the TestFlight build on an owner device signed into iCloud.
2. Create a child profile.
3. Add at least one event so the child zone has real data.
4. Open the Sharing screen and confirm the share button is enabled.
5. Send an invite to a second physical device signed into a different Apple ID.
6. Accept the invite and confirm the shared child appears on the caregiver device.
7. Create an event on the caregiver device and confirm it syncs back to the owner device.

## 8. Common Failure Cases

- Share button disabled: CloudKit sync is currently unavailable on the device. Check iCloud sign-in and CloudKit capability setup.
- Share sheet shows an error: Production CloudKit schema is missing or the app/container entitlements do not match the distribution profile.
- Invite accepted but shared data is incomplete: the owner device may not have pushed all zone records yet. Make a change on the owner device to force another sync.
