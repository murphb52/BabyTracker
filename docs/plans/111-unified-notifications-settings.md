# 111 — Unified Notifications Settings Screen

## Goal

Replace the current fragmented notification configuration experience with a single "Notifications" screen in Settings that surfaces all notification types in one place — activity reminders (drift) and medication reminders — alongside permission state and easy access to system Settings if permission is denied.

---

## Background

The app currently has two notification systems that the user manages in different places:

- **Activity reminders** (sleep drift, inactivity drift) — toggled via a single on/off switch somewhere in the profile/settings UI. These are passive, heuristic-based nudges the app schedules automatically.
- **Medication reminders** — configured per-dose at log time inside the medication sheet. There is no settings entry point; the only way to see or cancel active medication reminders is from individual event cards.

Both systems already share a common technical foundation (`LocalNotificationManaging`) so no architectural collapse is needed. What is missing is a coherent user-facing home for all notification configuration.

---

## Proposed experience

A single "Notifications" section (or screen) accessible from the app's Settings/Profile area containing:

### Activity reminders

- On/off toggle (maps to the existing `isReminderNotificationsEnabled` setting)
- Short description: "Get nudged when nothing has been logged for a while, or when sleep is running unusually long."
- If permission is denied: inline prompt — "Notifications are disabled. Enable them in Settings." with a link.

### Medication reminders

- Not a toggle (these are per-dose, not a global on/off)
- Shows a count of active reminders: "2 active reminders" → tappable row that expands or navigates to a list of pending medication reminders
- Each reminder in the list shows: medicine name, child name, fire time, cancel button (with confirmation)
- If no active reminders: "None set — reminders are configured when logging a dose."
- Short description of the feature for discoverability.

### Notification permission state

- If permission is not yet determined: show a "Turn on notifications" prompt that requests permission inline.
- If permission is denied: show a persistent banner across all notification types explaining they are all disabled, with an "Open Settings" link.
- If permission is granted: no banner; each section manages its own state.

---

## Goals

- One place for the user to understand what notifications are active and why.
- Permission state is visible and actionable from a single location.
- Medication reminders become discoverable without requiring the user to open a past event.
- Activity reminders retain their existing toggle behaviour.
- No change to the per-dose reminder setup flow in the medication sheet (it stays there).

---

## Out of scope

- Changing how medication reminders are configured (stays in the logging sheet).
- Adding new notification types.
- Merging the underlying data models or use cases — the architecture is already unified through `LocalNotificationManaging`.

---

## Next step: technical investigation

Before implementation begins, a focused investigation is needed to answer:

1. **Where does the activity reminders toggle currently live?** Identify the exact view, the binding into `AppModel.isReminderNotificationsEnabled`, and any related settings rows so the new screen can absorb or replace them without duplication.

2. **How are pending medication reminders queried?** Review `AppModel.pendingMedicationReminders` and `LocalNotificationManaging.pendingMedicationReminderNotifications()` — confirm they provide enough data (child name, medicine name, fire date) to populate a list view, or identify what additions are needed.

3. **What is the current permission check/request flow?** Map the full path from `LocalNotificationManaging.isAuthorizedForNotifications()` / `requestAuthorizationIfNeeded()` through `AppModel` to the UI — confirm what needs to be exposed for the unified permission banner.

4. **Where should the Notifications screen live in the navigation hierarchy?** Review the current Settings/Profile structure to identify the right insertion point and whether it warrants a dedicated screen or an expanded section within an existing settings view.

5. **Child scoping for medication reminders.** Medication reminders are per-child. The settings screen should clarify whether it shows reminders for the currently selected child only, or all children. Decide and document the answer before building the list view.

---

- [ ] Complete
