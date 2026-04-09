## Goal

Keep the CloudKit sharing fixes, but remove the temporary diagnostic noise and leave behind comments that explain the non-obvious sync behavior.

## Approach

The recent fixes added detailed push and pull logging so the owner and caregiver sync paths could be compared on real devices. That helped diagnose the issue, but the logs are too noisy to keep as the long-term explanation of the design.

Update the sync code so:

- temporary diagnostic logs are removed
- the share-accept path explains why it forces a full pull
- the owner refresh and push paths explain why shared private zones are reconciled before continuing
- the record mapper explains why shared records need a parent-child hierarchy

Also remove the captured device log from the staged project changes.

- [x] Complete
