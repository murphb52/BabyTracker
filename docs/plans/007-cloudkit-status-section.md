# 007 CloudKit Status Section

## Summary

Add a small `iCloud Sync` section to the child profile screen so the user can tell whether local data has synced, whether anything is still pending, and when the last successful sync happened.

## Tasks

1. Add a dedicated status view state derived from `SyncStatusSummary`.
2. Replace the single-line sync banner with a richer `iCloud Sync` section in the child profile screen.
3. Show a simple backup status, last sync time, pending change count, and any relevant detail message.
4. Add focused tests for the new status mapping.

- [x] Complete
