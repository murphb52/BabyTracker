# 003 Stage 1: Child Profile, Identity, and Sharing

## Summary

Implement the first real app flow after Stage 0 by replacing the foundation placeholder with a local-first child profile experience. Stage 1 creates and persists the local caregiver identity, creates and edits a child profile, manages owner and caregiver memberships locally, enforces role permissions in code, and exposes a temporary in-app invite, accept, and remove UI so the sharing lifecycle can be exercised before real CloudKit sharing arrives in Stage 2.

## Locked Decisions

1. Sharing stops at local scaffolding in Stage 1. No real CloudKit share sending, acceptance, or cross-device access yet.
2. Identity is mixed: Stage 1 captures a local `displayName` and also stores an optional future CloudKit user linkage field.
3. The product remains single-child-first in the UI. Storage may hold multiple children, but multi-child management is not a first-class Stage 1 feature.
4. If more than one active accessible child exists, show a simple fallback picker rather than choosing one implicitly.
5. Caregiver acceptance is exposed as a clearly temporary local UI action in Stage 1 so the full lifecycle can be tested manually.
6. Archiving is soft only. Archived children are hidden from the main flow and can be restored from an archived list so the app never traps the user after archiving the only child.

## Work Items

1. Extend the domain layer with validation errors, permission checks, and membership lifecycle helpers.
2. Replace the placeholder repository seam with a SwiftData-backed child profile repository.
3. Replace the placeholder root state with a Stage 1 app model that chooses between onboarding, child creation, child picking, and child profile routes.
4. Build the SwiftUI screens for identity setup, child creation, child profile management, caregiver invites, and archived child restore.
5. Add tests for validation, permissions, membership lifecycle, persistence, and Stage 1 UI flows.

## Exit Criteria

1. First launch creates a local caregiver identity and a child profile.
2. Child details can be edited and archived.
3. Caregiver invite, activate, and remove flows work locally.
4. Owner-only actions are hidden from active caregivers.
5. Archived children are excluded from the active route and can be restored.
6. `./scripts/validate.sh` passes.

- [x] Complete
