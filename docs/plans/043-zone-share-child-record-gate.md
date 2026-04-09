# 043-zone-share-child-record-gate.md

## Goal
Allow zone-share creation without a full zone snapshot by ensuring only the child record exists on the server before creating the zone-wide share.

## Plan
1. Update `prepareShare()` so it stops calling `pushZoneSnapshot()` during share preparation.
2. Ensure the private zone exists, then check whether the child record already exists remotely in that zone.
3. If the child record is missing, upload only the child record and mark its sync metadata up to date.
4. Keep the rest of the share flow small: look up the existing zone-wide share, delete any legacy record-level share, and create `CKShare(recordZoneID:)` only when needed.
5. Add regression tests for both cases:
   - the child record is missing remotely, so `prepareShare()` uploads only the child record before creating the share
   - the child record is already remote, so `prepareShare()` saves only the share
6. Run the targeted sync-engine tests and mark the plan complete.

- [x] Complete
