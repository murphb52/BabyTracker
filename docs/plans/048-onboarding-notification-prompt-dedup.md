## Goal

Stop the onboarding notification prompt from appearing twice after the user has already responded to the system notification alert.

## Approach

1. Add explicit notification authorization state tracking to the onboarding view.
2. Show the in-app notification prompt only on the sharing page when the status is still `notDetermined`.
3. Once the in-app prompt has been shown during the current onboarding session, let `Continue` advance instead of showing it again.
4. Keep the status refresh simple and guard the permission flow so the onboarding view cannot trigger overlapping prompts.

- [x] Complete
