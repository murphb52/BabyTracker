# 081 Firebase analytics and Crashlytics integration

## Goal
Integrate a minimal Firebase setup that supports Analytics + Crashlytics while keeping the app architecture clean and testable.

## Approach
1. Add a domain-level analytics boundary (protocol + event model + no-op implementation).
2. Add Firebase dependencies and concrete Firebase analytics/crash reporting adapters in `BabyTrackerFeature`.
3. Thread analytics through `AppModel` and track key use-case actions (success/failure) using the protocol.
4. Add a simple Firebase bootstrap entrypoint and call it during app startup.
5. Run relevant tests/checks and update this plan as complete.

## Notes
- Keep tracking payloads minimal and explicit.
- Use defaults so previews/tests continue to run without Firebase configuration files.

- [x] Complete
