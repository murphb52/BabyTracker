# 030 - Live Activity user controls

## Goal
Add a persistent in-app preference that lets users disable Live Activities and immediately end any active activity.

## Plan
1. Add a small persistence boundary for the Live Activity preference and inject it through the app container.
2. Update the live activity synchronization flow to respect the preference and end active activities when disabled.
3. Add a settings control in Profile for the global on/off preference.
4. Document the platform limitation by shipping only a reliable global toggle unless the platform exposes finer control.
5. Add or update tests covering preference persistence and synchronization behavior.

- [x] Complete
