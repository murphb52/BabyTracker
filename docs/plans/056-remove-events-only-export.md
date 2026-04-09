## Goal

Remove the separate events-only Nest export mode and keep a single full backup export format.

Users should still be able to:

1. restore a backup into a brand-new child from the Add Child flow
2. import events from that same backup file into an existing child profile

## Approach

1. Simplify `ExportEventsUseCase` so it always writes one full backup payload that includes child profile data.
2. Remove export mode state and picker UI from the export screen so the product only exposes one export action.
3. Keep both import paths intact:
   - full-child restore from the Add Child flow
   - event import into an existing child from the existing child import flow
4. Add a focused test that locks in the new export contract.

- [x] Complete
