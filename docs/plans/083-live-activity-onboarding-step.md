# 083 — Live Activity Onboarding Step

## Goal

Add a new onboarding page between "Spot the patterns" and profile setup that showcases the lock-screen Live Activity with ticking demo data.

GitHub issue: #196

## Approach

1. Insert a new demo step into `InteractiveOnboardingView` after the charts page and before caregiver setup.
2. Add a dedicated `OnboardingLiveActivityDemoView` inside `BabyTrackerFeature` so the onboarding can present the Live Activity without depending on the widget target.
3. Use the shared `BabyTrackerLiveActivities` package for the dummy content-state model, but keep the visual rendering local to the feature package to preserve package boundaries.
4. Present the demo inside a stylized iPhone frame with the lock-screen content anchored low on the screen and a fade mask over the top third so the eye stays on the Live Activity.
5. Update onboarding previews and page-indicator counts to reflect the extra demo page.

## Notes

- Apple’s design resources provide official product bezels, but their marketing guidelines also limit modification and cropping of those images. For the in-app onboarding demo, use Apple’s public resources as visual reference only and render a simple SwiftUI device shell locally.

## Verification

1. The new Live Activity page appears after "Spot the patterns" and before caregiver name entry.
2. The demo shows a partial device frame with the Live Activity near the bottom and a faded top section.
3. Timer text in the demo updates live while the page is visible.
4. Skip behavior still jumps from any demo page to caregiver setup.
5. Onboarding previews still line up with the correct steps.

- [x] Complete
