# 028 Onboarding Flow

## Goal
Replace the current single-step identity prompt with a clearer onboarding flow that explains the app's value, reduces first-run friction, and leads cleanly into creating the local user and first child.

## Scope
1. Keep onboarding focused on the first-run path only.
2. Add a small set of value-focused onboarding pages before account setup.
3. Keep the final step lightweight by asking only for the minimum information needed to enter the app.
4. Lead directly into first-child creation so users do not land in an empty app without guidance.
5. Add subtle motion that improves clarity without slowing down the flow.

## Notes
- The current onboarding entry point is `IdentityOnboardingView`.
- The app already has child creation and child selection flows, so this work should connect to those rather than introducing a parallel setup system.
- Motion should remain simple and optional, with Reduce Motion respected.

## Plan
1. Review the current first-run flow from app launch through local user creation and first child setup.
2. Introduce onboarding state that supports a short carousel or paged intro before the identity form.
3. Design 2 to 4 concise onboarding pages that explain:
   - what can be tracked
   - why logging is useful
   - how sharing with another caregiver works
4. Add clear primary and secondary actions:
   - continue
   - skip intro when appropriate
   - get started
5. Replace the current single-screen onboarding view with a staged flow that still ends in local user creation.
6. Hand off immediately to child creation when there is no active child yet.
7. Add subtle transitions or page animations that feel polished but do not add complexity.
8. Add or update tests for onboarding state and the first-run decision path.
9. Run targeted validation for the updated first-run experience.

## Acceptance Criteria
1. First launch no longer drops users straight into a bare name-entry form.
2. Users can understand the app's value before entering data.
3. The onboarding flow stays short and never blocks users behind unnecessary input.
4. The final onboarding step still creates the local user with the same core behavior as today.
5. A user with no child profile is guided into creating one immediately after onboarding.
6. Reduce Motion users do not get forced into unnecessary animation.
7. Tests cover the new first-run flow decisions where practical.

## Out of Scope
1. Reworking existing child edit or profile management flows beyond what is needed for first-run entry.
2. Adding network-backed onboarding content or remote configuration.
3. Building a full tutorial system for every screen in the app.

- [x] Complete
