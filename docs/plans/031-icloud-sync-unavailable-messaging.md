# 031 iCloud Sync Unavailable Messaging

## Goal
Reduce repeated iCloud account error messaging so users see one clear explanation on the iCloud Sync screen instead of multiple banners across the app.

## Scope
1. Detect when sync is unavailable because the user is not signed into iCloud or iCloud is otherwise unavailable.
2. Keep the detailed explanation on the iCloud Sync screen.
3. Remove repeated top-level error and sync banners for that specific account state.
4. Keep other screens concise when sharing or syncing is unavailable.

## Notes
- The current sync status is shaped by `CloudKitStatusViewState`.
- Repeated messaging currently appears through `ErrorBannerView`, `SyncIndicatorView`, timeline sync copy, and sharing copy.
- Local data should still be presented as safe and available on device.

## Plan
1. Add explicit account-unavailable classification to `CloudKitStatusViewState`.
2. Add dedicated sync-screen banner copy for the account-unavailable state.
3. Suppress app-wide error banners for account-unavailable messages in `AppModel`.
4. Suppress transient sync indicator banners for the same state.
5. Hide timeline inline sync messaging when the issue is specifically missing iCloud access.
6. Shorten sharing copy so it points users to the iCloud Sync screen instead of repeating the full account error.
7. Add tests for the new classification and the suppressed repeated messaging behavior.

## Acceptance Criteria
1. The iCloud Sync screen shows one clear explanation when iCloud backup is unavailable.
2. The app no longer repeats the same iCloud account error through top-level banners and transient sync indicators.
3. Sharing remains unavailable while iCloud backup is unavailable, with concise guidance.
4. Tests cover the unavailable classification and the suppressed repeated messaging behavior.

## Out of Scope
1. Changing generic sync failure handling for non-account-related errors.
2. Adding Settings deep links or account repair flows.
3. Changing persistence or CloudKit sync logic itself.

- [x] Complete
