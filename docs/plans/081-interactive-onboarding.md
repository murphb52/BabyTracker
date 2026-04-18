# 080 — Interactive Onboarding Experience

## Goal

Replace the static 4-page intro onboarding with a rich, interactive multi-step experience that:
- Showcases the app's core features through inline demo views
- Integrates baby setup directly into the onboarding
- Guides the user through logging their first real event
- Shows what the app looks like with live data before entering the main UI

## Problem

The existing `IdentityOnboardingView` shows 4 static, text-only intro pages followed by a caregiver name entry. After completing it, users land on a separate "no children" screen to add their baby. There is no guided first-event logging, no feature demos with real data, and no sense of what the app looks like populated.

## Approach

A new `InteractiveOnboardingView` is presented as a `fullScreenCover` from `AppRootView` whenever `model.isInteractiveOnboardingActive` is true. Using a full-screen cover rather than a route-based view means the onboarding survives the route changes that occur when `createLocalUser` and `createChild` are called mid-flow (which would otherwise transition the route away from `.identityOnboarding`).

`AppModel.refresh()` sets `isInteractiveOnboardingActive = true` the first time it finds no local user, triggering the interactive onboarding on first launch. The replay-from-settings path (`showOnboarding()` from Profile) is unaffected — it sets `route = .identityOnboarding` with a local user already present, so `isInteractiveOnboardingActive` is never set and `IdentityOnboardingView` shows as before.

### 8-step flow

| Step | Name | What it shows |
|------|------|---------------|
| 0 | Welcome | Existing `OnboardingIntroStepView` with the pain-points page |
| 1 | Quick Log Demo | `OnboardingQuickLogDemoView` — static replica of the 4 quick-log buttons |
| 2 | Timeline Demo | `OnboardingTimelineDemoView` — scaled `TimelineWeekView` with demo data |
| 3 | Charts Demo | `OnboardingChartsDemoView` — scaled `SummaryScreenView` with preview data |
| 4 | Caregiver Name | `IdentityOnboardingNameStepView` (reused unchanged) |
| 5 | Baby Setup | `OnboardingAddBabyStepView` — name + optional birthdate form |
| 6 | First Event | `OnboardingFirstEventStepView` — real interactive quick-log buttons + editor sheets |
| 7 | App Preview | `OnboardingAppPreviewStepView` — non-interactive `ChildHomeView` with live data |

Steps 0–3 have a "Skip" button in the top bar that jumps to step 4 (caregiver name). Steps 5, 6 have a "Skip for now" link in the footer that exits the onboarding. Step 7 has "Let's Go" which dismisses the cover.

At step 4, `model.createLocalUser()` is called — route changes to `.noChildren` but the full-screen cover stays visible.
At step 5, `model.createChild()` is called — route changes to `.childProfile`.
At step 6, the real event editors are presented and events are saved to the live database.
At step 7, the real `ChildHomeView` renders with the just-logged event visible.

Demo views use static data from `OnboardingDemoDataFactory` (timeline) and `SummaryScreenPreviewFactory` (charts). All demo views have `allowsHitTesting(false)`.

## Files changed

**New files (all in `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/`):**
- `Views/InteractiveOnboardingView.swift` — root container
- `Views/OnboardingAddBabyStepView.swift` — step 5 baby form
- `Views/OnboardingFirstEventStepView.swift` — step 6 first event logging
- `Views/OnboardingAppPreviewStepView.swift` — step 7 live Home screen embed
- `Views/OnboardingQuickLogDemoView.swift` — step 1 Quick Log demo
- `Views/OnboardingTimelineDemoView.swift` — step 2 Timeline demo
- `Views/OnboardingChartsDemoView.swift` — step 3 Charts demo
- `OnboardingDemoDataFactory.swift` — static demo data factory

**Modified files:**
- `AppModel.swift` — added `isInteractiveOnboardingActive` property; set it in `refresh()` when `localUser == nil`
- `Baby Tracker/App/AppRootView.swift` — added `fullScreenCover` driven by `isInteractiveOnboardingActive`

**Unchanged:**
- `IdentityOnboardingView.swift` — still used for settings replay path, no changes

## Verification

1. **First launch:** Delete app data / fresh install → interactive onboarding shows, all 8 steps work end-to-end, "Let's Go" lands on Home tab with logged event visible.
2. **Skip paths:** Skip on steps 0–3 jumps to name entry. "Skip for now" on step 5 lands on noChildren screen. "Skip for now" on step 6 lands on Home tab.
3. **Settings replay:** Profile → Replay Onboarding → legacy 4-page static flow shows.
4. **Second child:** Add second child from Profile → noChildren → ChildCreationView path unaffected.
5. **Tests pass:** `xcodebuild test` succeeds.

- [x] Complete
