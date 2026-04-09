## Goal

Ensure notification permission is only requested from the onboarding flow.

## Approach

1. Remove launch-time notification authorization from the app root view.
2. Remove app-launch remote notification registration from the app delegate.
3. Leave the notification manager focused on requesting authorization only when another flow explicitly asks for it.
4. Verify the app still builds after the cleanup.

- [x] Complete
