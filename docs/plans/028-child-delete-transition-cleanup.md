# 028 - Child delete transition cleanup

## Goal
Make child deletion transitions clearer by showing a success banner, switching to a valid remaining child, and avoiding stale navigation on deleted-child screens.

## Plan
1. Review the current hard-delete flow and identify the minimum state needed for a post-delete success banner and deterministic navigation reset.
2. Extend the feature state so a successful delete can trigger a transient success message without affecting unrelated banners.
3. Update the root/profile navigation flow so deleting the current child returns the user to a sensible top-level state.
4. Add or update tests covering remaining-child selection and empty-state routing after delete.

- [x] Complete
