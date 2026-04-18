## Goal

Adjust inactivity reminders so they nudge sooner during the day and stay less aggressive overnight.

## Approach

1. Keep the inactivity timing rule inside the existing domain use case.
2. Reuse the app's existing daytime window of 6am to 10pm.
3. Fire inactivity reminders after 6 hours for events logged during daytime.
4. Fire inactivity reminders after 12 hours for events logged during nighttime.
5. Update domain tests to cover both day and night cases.

- [x] Complete
