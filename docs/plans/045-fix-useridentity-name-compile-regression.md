# 045 Fix `UserIdentity.name` compile regression

## Goal
Restore compatibility for code paths that still reference `UserIdentity.name` so the project compiles cleanly in PR #150.

## Approach
1. Add a lightweight computed `name` property on `UserIdentity` that returns `displayName`.
2. Mark `name` as deprecated with a message directing call sites to `displayName`.
3. Run targeted package tests to verify the domain package still builds and tests pass.

- [x] Complete
