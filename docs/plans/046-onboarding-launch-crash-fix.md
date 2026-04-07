## Goal

Stop the launch crash that occurs on fresh installs when the app opens `IdentityOnboardingView`.

## Approach

1. Confirm the crash path from simulator crash reports and narrow it to onboarding.
2. Remove the most complex SwiftUI state and layout interactions from the onboarding intro flow.
3. Keep the same onboarding content and navigation, but render a single page at a time instead of using a `TabView` pager.
4. Verify the app builds and launches on the iPhone 17 Pro simulator without producing a fresh crash report.

- [x] Complete
