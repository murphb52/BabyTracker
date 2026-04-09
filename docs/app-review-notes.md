# App Review Notes

Use the following notes when submitting Baby Tracker for review.

## Suggested App Review Notes

Baby Tracker is an iOS app for shared baby care tracking. Caregivers can log feeds, sleep, and nappy changes, then review current status and history across devices.

Key behaviors used by the app:

- iCloud / CloudKit sync keeps child profiles and event history in sync across the user's devices.
- Caregiver sharing uses iCloud sharing so an invited caregiver can access the same child profile.
- The app supports optional child photos, local import from backup files, local export, and Live Activities.

Reviewer guidance:

1. Launch the app and complete onboarding.
2. Create a child profile.
3. Log at least one feed, sleep, or nappy event.
4. Open the child's Sharing screen to see the caregiver sharing entry point.
5. Open the Sync Status screen to verify iCloud-related messaging.

Important notes:

- Full caregiver sharing validation requires iCloud to be signed in.
- End-to-end sharing is best tested with two physical devices using two different Apple IDs.
- If iCloud is unavailable on the review device, the app still works locally, but sync and sharing actions will be unavailable.
