# 084 — Notification Onboarding Step

## Goal

Add a dedicated onboarding page after the Live Activity demo that previews Nest notifications and requests push permission from that screen.

GitHub issue: #197

## Approach

1. Insert a new onboarding step after the Live Activity page and before caregiver setup.
2. Add `OnboardingNotificationsDemoView` with three staged notification cards that resemble iOS notifications and animate in sequentially.
3. Move notification permission prompting off the caregiver-name submit path and onto the new page's Continue action.
4. If permission is already granted, continue immediately. If it is not granted, show a pre-prompt alert and only call the native notification request after confirmation.
5. Update previews and onboarding page-indicator counts to match the extra intro step.

## Notes

- The notification cards should read like realistic examples from Nest, but stay clearly demo data.
- If the user declines the pre-prompt alert, continue onboarding without blocking setup.

## Verification

1. The notifications page appears after the Live Activity page.
2. Three notification cards animate in one after another.
3. Tapping Continue on that page advances immediately when notifications are already authorized.
4. Tapping Continue when notifications are not authorized shows a pre-prompt alert first.
5. Confirming the alert triggers the native request and then advances.
6. Declining the alert continues onboarding without requesting permission.

- [x] Complete
