# 029 - Shared child image sync

## Goal
Ensure child profile images sync reliably across CloudKit sharing, including initial share acceptance, later updates, and image removal.

## Plan
1. Review the current child image save, CloudKit mapping, and accepted-share refresh path to find the missing behavior.
2. Fix the sync path with the smallest change that keeps image handling at the child-record boundary.
3. Add focused tests for image upload, update, and removal behavior in the CloudKit mapping/sync flow.
4. Validate that the shared child image remains visible in existing presentation code without UI-specific workarounds.

- [x] Complete
