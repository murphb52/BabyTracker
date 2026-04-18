## Goal

Make reminder notifications easier to understand and control.

## Approach

1. Add a persisted reminder notification preference using the same pattern as live activities.
2. Update `AppModel` so reminder scheduling only runs when the preference is enabled and cancels pending reminders when disabled.
3. Rename the user-facing feature from "Drift Reminders" to "Reminder Notifications".
4. Move the navigation entry from App Settings to the main Profile screen under Live Activities.
5. Update the reminders screen to include a toggle and clearer explanatory copy.

- [x] Complete
