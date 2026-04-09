# 075 Requested UI Settings Polish

GitHub issue: #177

## Goal

Implement the requested UI and settings refinements across live activity handling, sync wording, event history headers, summary ordering, Help & FAQ content, onboarding transitions, and caregiver profile editing.

## Plan

1. Stop presenting the end sleep sheet when the app opens from the live activity, while still switching to the relevant child.
2. Change the iCloud sync status copy to display `Last Synced: {relative time ago}` and avoid future-facing wording.
3. Replace event history date pills with full-width section headers that align the title to the leading edge.
4. Move Sleep to the top of the Today and Trends summary layouts and review the Help & FAQ copy so it matches the current app structure and terminology.
5. Add entrance and exit transitions for onboarding so it appears and dismisses more smoothly.
6. Add a profile/settings flow that lets the active caregiver update their display name after onboarding.
7. Verify the affected behavior with focused tests and a project build, then mark the plan complete.

- [x] Complete
