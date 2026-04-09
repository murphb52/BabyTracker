## Goal

Ensure that when a user accepts a CloudKit share, the app forces a full pull of the accepted shared zone so the shared child data is downloaded locally immediately.

## Plan

1. Update the share acceptance flow in `CloudKitSyncEngine`.
   - Accept the share with CloudKit.
   - Force a full fetch of the accepted shared zone using the zone from the share metadata.
   - Keep the existing follow-up refreshes so normal sync state stays consistent.

2. Make acceptance fail when the forced pull or follow-up refresh fails.
   - Do not report share acceptance as complete if the shared data could not be fetched locally.

3. Add focused tests for the forced-pull path.
   - Verify the accepted shared zone is fetched with a nil token.
   - Verify the fetched child data is saved locally.

- [x] Complete
