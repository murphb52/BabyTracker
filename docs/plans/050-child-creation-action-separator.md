# 050 Child Creation Action Separator

## Goal
Make the create child screen more explicit about the two available paths: creating a new child profile or restoring one from a backup.

## Approach
1. Update `ChildCreationView` to add a divider above the primary create action.
2. Add an `OR` label under the divider so the restore section reads as the alternative path.
3. Keep all existing create and restore behavior unchanged.
4. Run the relevant package tests to confirm the UI change is safe.

## Notes
- This is a small presentation-only adjustment to clarify the screen flow.
- No separate GitHub issue was created because the change is intentionally small.
- `swift test --package-path Packages/BabyTrackerFeature` is currently blocked by existing macOS availability errors in `BabyTrackerDomain`, unrelated to this UI change.

- [x] Complete
