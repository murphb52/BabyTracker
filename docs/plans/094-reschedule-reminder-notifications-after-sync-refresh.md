## Goal

Keep reminder notifications in sync when another caregiver updates a child's timeline through sync, not only when the current user logs an event locally.

## Approach

- Update the sync refresh path to reschedule reminder notifications after the app refreshes the selected child's data.
- Keep the change at the shared sync boundary so foreground refreshes, launch refreshes, and remote-change refreshes all benefit.
- Add or update a focused test to prove reminder notifications are rescheduled after sync-driven timeline updates.
- Verify the app builds and the relevant test coverage passes.

- [x] Complete
