# 025-profile-multi-child-management.md

## Goal
Improve Profile so multi-child families can manage children in one place by adding a child and switching directly without a separate switch flow.

## Plan
1. Review current multi-child behavior in domain + feature layers.
2. Extend profile state in the feature layer so Profile has the child list needed for direct selection and can show add-child when local creation is allowed.
3. Update the Profile UI to:
   - add an "Add Child" entry point
   - show direct child selection rows in Profile
   - remove reliance on the separate "Switch Child" row
4. Keep existing child selection persistence behavior by reusing `AppModel.selectChild(id:)`.
5. Add/update tests for the new profile state needed by the UI.
6. Run targeted tests.

- [x] Complete
