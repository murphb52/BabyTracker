# 054 — Replay Onboarding from Settings

## Goal

Add an option in App Settings that lets a user restart the onboarding sequence. This is useful for users who want to revisit the intro walkthrough or who share a device and want to understand the app's features.

## Approach

1. Add a `showOnboarding()` method to `AppModel` that sets `route = .identityOnboarding`.
2. Add a "Start Onboarding" button to a new "Help" section in `AppSettingsView`.
3. Tapping the button sets the route immediately — no confirmation needed, since the action is non-destructive and the user returns to their normal session after completing or dismissing onboarding.

## Files Changed

- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift` — add `showOnboarding()`
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/AppSettingsView.swift` — add "Help" section with button

## Out of Scope

- No changes to the onboarding flow itself.
- No persistence of "has seen onboarding" flag changes.

---

GitHub Issue: murphb52/BabyTracker#151

- [x] Complete
