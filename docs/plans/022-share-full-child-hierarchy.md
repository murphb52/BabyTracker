## Goal

Ensure CloudKit sharing includes the full child hierarchy, not just the root child record.

## Approach

CloudKit sharing follows the share root's parent-child record hierarchy. The current mapper saves memberships, user identities, and events in the same zone, but does not attach them to the child record with a `parent` reference. That allows the child record to appear in a share while the rest of the child data remains outside the shared hierarchy.

Update the CloudKit record mapper so:

- membership records point to the child record as their parent
- user identity records point to the child record as their parent
- event records point to the child record as their parent

Then add mapper tests that verify those parent references are present.

- [x] Complete
