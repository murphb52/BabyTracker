## Goal

Show an explicit success screen after restoring a child from a Nest backup in the Add Child flow.

The screen should:

1. confirm that a new child profile was restored
2. show what was imported
3. provide a Continue button that returns to the Profile screen with the restored child selected

## Approach

1. Return the restored child and import result from the Add Child restore path.
2. Add local success-screen state to `ChildCreationView`.
3. Reuse the existing import-complete presentation pattern, but tailor the copy for full child restore.
4. Dismiss the Add Child screen from the success state so the user lands back on Profile with the new child already selected.

- [x] Complete
