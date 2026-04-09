# 071 Skip Redundant Onboarding Profile Step

## Goal
Avoid showing the local profile creation step when onboarding is replayed after a local user already exists on the device.

## Approach
1. Keep the first-run onboarding flow unchanged for users who do not have a local profile yet.
2. Treat onboarding as a replay when `AppModel` already has a local user.
3. Finish the onboarding intro directly back into the normal app flow instead of pushing the profile-name step again.
4. Add a focused test that covers replaying onboarding with an existing local user and returning to the expected route.

## Notes
- This change only affects replayed onboarding from the existing app session.
- First-run onboarding should still end by creating the local user and then handing off to child creation.

- [x] Complete
