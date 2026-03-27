## Goal

Ensure owner devices receive caregiver-authored records from shared child zones and do not overwrite missing remote changes with stale local snapshots.

## Approach

The logs show caregiver writes land in the expected shared zone, but owner devices sometimes see zero incremental changes in the corresponding private zone. The current sync flow can then push a stale local snapshot back to the owner's private zone.

Add an owner-side reconciliation rule for private zones that already have a share:

- detect private child contexts that represent shared zones
- force a full zone pull for those contexts during normal refreshes
- force a full reconciliation pull immediately before pushing one of those zones

This keeps the owner's local state aligned with caregiver-authored records before any private-zone push occurs.

Also add a focused sync test that proves a stale owner snapshot is reconciled from the private shared zone before a local-write refresh pushes data.

- [x] Complete
