# 099 Gate Debug Settings Rows Behind Deep Link

1. Add a persisted flag that controls whether debug-only settings rows are visible.
2. Handle `babytracker://debug-options` in the app root deep-link entry point and set that flag when opened.
3. Group `Logs` and onboarding-related rows under one debug section in App Settings.
4. Hide that debug section unless the flag is enabled.
5. Keep existing non-debug settings sections unchanged.

- [x] Complete
