## Goal

Avoid reminder notifications always firing at exactly the same hour mark by adding a small random minute offset to the reminder thresholds.

## Approach

- Add a random offset of 1–60 minutes to both inactivity and sleep drift threshold calculations.
- Keep the randomness inside the domain use cases, as requested.
- Make the offset injectable for tests so coverage stays deterministic.
- Update threshold tests to verify the base threshold plus the injected offset.

- [x] Complete
