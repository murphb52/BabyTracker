# 027 - Share accept loading screen

## Goal
Show a dedicated full-screen loading state while the app is accepting a CloudKit share and pulling the shared child data locally.

## Plan
1. Add explicit share-acceptance UI state to the feature layer so the app can route to a loading screen during acceptance.
2. Update the share acceptance bridge/container wiring so the loading state starts before the async accept flow and ends on success or failure.
3. Add a focused SwiftUI loading screen in the app root that explains the app is accepting the share and downloading data.
4. Keep existing success and failure handling intact, but route failures back to a user-visible error after exiting the loading screen.
5. Add or update tests for the acceptance state transitions.

- [x] Complete
