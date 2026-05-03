# 107 Settings Event Type Checklist

1. Reuse the richer onboarding event-type checklist UI for the settings event visibility screen instead of maintaining a separate plain toggle list.
2. Extract the shared event-type selection card into a focused SwiftUI view so onboarding and settings stay visually aligned without duplicating row layout and copy.
3. Keep the existing event visibility behavior intact, including preventing the last enabled event type from being turned off and allowing a reset back to all event types.
4. Preserve the onboarding presentation while adapting the settings screen to use the fuller checklist-style layout and guidance copy.
5. Build the affected app target or package path to confirm the refactor compiles cleanly.

- [x] Complete
