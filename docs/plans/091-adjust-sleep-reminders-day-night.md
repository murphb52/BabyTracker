## Goal

Adjust sleep reminders so they use a simpler day/night timing rule instead of a single fixed threshold.

## Approach

1. Keep the sleep timing rule inside the existing domain use case.
2. Reuse the app's existing daytime window of 6am to 10pm.
3. Fire sleep reminders after 6 hours for sleeps that start during daytime.
4. Fire sleep reminders after 12 hours for sleeps that start during nighttime.
5. Update domain tests to cover both day and night sleep cases.

- [x] Complete
