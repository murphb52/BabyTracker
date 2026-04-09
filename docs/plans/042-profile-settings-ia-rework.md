# 042-profile-settings-ia-rework.md

## Goal
Rework the Profile tab so it is clearly child-first, move app and device concerns into a dedicated App Settings screen, and separate destructive child actions from account-level reset actions.

## Plan
1. Review the existing Profile, Settings, Sharing, Sync, and child-management views to confirm the current supported tasks and reuse points.
2. Restructure the Profile root into grouped sections for child details, family and sharing, profile management, and support.
3. Split child-specific preferences and child lifecycle actions into dedicated screens:
   - child details for identity only
   - feeding preferences for bottle volume units
   - manage child for archive, leave, and permanent delete flows
4. Replace the existing child profile settings screen with an app-focused settings screen for sync, Live Activities, import/export, logs, and erase-everything.
5. Promote archived child restore into a dedicated archived profiles screen and remove restore controls from child creation.
6. Reorder the iCloud sync screen so primary status appears first and advanced diagnostics are clearly separated.
7. Add or update SwiftUI previews for touched and newly created views.
8. Run a build to verify the feature compiles cleanly.

- [x] Complete
