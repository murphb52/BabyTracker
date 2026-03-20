# 001 MVP Project Management

## Summary

This document is the project-management tracker for the Baby Tracker MVP. It converts the product requirements document and technical design specification into a staged execution list with explicit dependencies, statuses, and exit criteria.

Source documents:
- [Simple_Baby_Tracker_PRD.md](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/docs/Simple_Baby_Tracker_PRD.md)
- [Simple_Baby_Tracker_Technical_Design_Spec.md](/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/docs/Simple_Baby_Tracker_Technical_Design_Spec.md)

Scope:
- MVP only
- Organised primarily by PRD stage
- Stage 0 added from the technical design spec because the current repo is still the default Xcode template and needs foundation work before feature delivery can start

Status legend:
- `Not Started`
- `In Progress`
- `Blocked`
- `Done`

Current baseline confirmed in repo:
- PRD exists
- Technical design spec exists
- Xcode app target exists
- Unit test target exists
- UI test target exists
- Stage 0 foundation plan exists
- Local Swift package scaffold exists
- Template app shell has been replaced with a foundation screen

## Stage 0: Foundation, Spec Alignment, and Delivery Setup

Stage summary: establish the delivery foundation, reconcile specification gaps, and replace the starter template structure with a project shape that can support the MVP safely.

Stage status: `In Progress`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S0-01 | Create `docs/plans` and this project-management document | Establish a single tracked place for staged execution status | None | `Done` | Implemented in this document |
| S0-02 | Confirm planning inputs are present in repo | Ensure execution is grounded in the PRD and technical spec already on disk | None | `Done` | Both source documents exist under `docs/` |
| S0-03 | Confirm current app/test baseline exists | Verify the repo already has an app target, unit tests, UI tests, and starter SwiftData scaffolding | None | `Done` | Current project is the default Xcode template |
| S0-04 | Reconcile `milkType` requirement mismatch | PRD says bottle `milkType` is optional, tech spec makes it required | S0-02 | `Done` | Canonical MVP rule is now `milkType` optional in both docs and domain scaffolding |
| S0-05 | Reconcile nappy attribute mismatch | PRD uses type, intensity, and colour; tech spec uses `kind` plus optional `PooDetails(color, consistency)` | S0-02 | `Done` | Canonical MVP rule is `type`, optional `intensity`, optional `pooColor`, no `PooConsistency` |
| S0-06 | Reconcile missing typed models for `Child`, `User`, and `Membership` | PRD defines these records, but the tech spec only types events | S0-02 | `Done` | Typed definitions now exist in docs and initial domain package scaffolding |
| S0-07 | Decide how the technical-spec packages map into the current Xcode project | Tech spec lists separate packages/modules that do not exist yet in the repo | S0-02 | `Done` | Stage 0 creates Domain, Persistence, Sync, and Feature packages; the rest are deferred until first use |
| S0-08 | Replace template app structure with MVP architecture | Move from template files to Presentation / Domain / Data / App Composition layering | S0-07 | `Done` | Template files were removed and replaced with `AppContainer`, `AppRootView`, and a new app entry point |
| S0-09 | Define feature folder structure and naming conventions | Keep future SwiftUI feature work readable and consistent | S0-07 | `Done` | Repo now uses app, config, package, script, and workflow folders that match the Stage 0 foundation plan |
| S0-10 | Configure signing, bundle IDs, and Apple capabilities | Required for iCloud, CloudKit, push, and Live Activities | S0-02 | `In Progress` | Bundle IDs and CloudKit container entitlements are in repo; local team selection and Apple portal confirmation still need manual completion |
| S0-11 | Create CloudKit container and environment setup plan | Shared sync and sharing cannot proceed without container/schema planning | S0-10 | `In Progress` | Setup steps are documented, but actual container creation and portal wiring still depend on manual Apple Developer work |
| S0-12 | Define Git workflow and PR expectations | Match the tech spec and AGENTS guidance for atomic changes and review flow | S0-02 | `Done` | Workflow expectations are documented and CI now validates pull requests |
| S0-13 | Define how local validation should run before commits | Keep test verification explicit without relying on repository-managed hooks | S0-12 | `Done` | `scripts/validate.sh` is the documented local validation command |
| S0-14 | Add CI plan for PR test runs | Shared-impact changes need automated verification | S0-12 | `Done` | GitHub Actions now runs the same simulator validation command as local development |
| S0-15 | Prepare testing account and device matrix | Shared sync and Live Activities need two iCloud accounts and device coverage | S0-10, S0-11 | `Blocked` | Needs real-device and multi-account setup outside the repo |

Exit criteria:
- Spec mismatches affecting event modeling, sharing, and validation are resolved or explicitly documented as locked decisions
- The repo has an agreed architecture and folder/module layout to implement against
- Apple capabilities, signing direction, and CloudKit setup approach are defined clearly enough to unblock feature work
- Git, CI, and local validation expectations are documented for implementation work
- Relevant unit tests added or updated where setup behavior changes
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed for any setup-facing UI
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 1: Child Profile, Identity, and Sharing

Stage summary: establish the child record, caregiver identities, and access-sharing model that the rest of the MVP depends on.

Stage status: `Complete`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S1-01 | Define domain models for `Child`, `User`, and `Membership` | Create the typed source-of-truth models required by the PRD access model | S0-06, S0-07 | `Not Started` | Must cover roles, statuses, created metadata, and archive state |
| S1-02 | Define persistence models for child and membership data | Enable local-first storage of child and caregiver relationships | S1-01, S0-08 | `Not Started` | Should align with the chosen persistence approach |
| S1-03 | Build child profile creation flow | The app needs at least one child profile before event tracking can begin | S1-01, S1-02 | `Not Started` | Include name, optional birth date, and owner metadata |
| S1-04 | Build child profile edit and archive flow | PRD includes editable child profile and archive support | S1-03 | `Not Started` | Archiving should not destroy event history |
| S1-05 | Implement first-launch identity and child selection/onboarding | Users need a clear path into the app on first run | S1-01, S1-03 | `Not Started` | Should keep cognitive load low and handle empty states clearly |
| S1-06 | Establish owner vs caregiver permission rules in code | The PRD defines role-based access and one owner per child | S1-01 | `Not Started` | Must cover create, edit, delete, invite, remove, and settings access |
| S1-07 | Implement invite caregiver flow | Required to support shared visibility between caregivers | S1-01, S1-02, S0-11 | `Not Started` | Depends on CloudKit sharing direction |
| S1-08 | Implement accept/remove caregiver lifecycle | Complete the invited to active to removed lifecycle from the PRD | S1-06, S1-07 | `Not Started` | Must revoke access for removed caregivers |
| S1-09 | Handle removed-caregiver access loss | PRD explicitly requires removed users to lose access to shared data | S1-08 | `Not Started` | Must be tested against sync edge cases |
| S1-10 | Add tests for membership lifecycle and permissions | Protect ownership and sharing behavior from regressions | S1-06, S1-07, S1-08, S1-09 | `Not Started` | Include owner-only actions and caregiver restrictions where applicable |

Exit criteria:
- Child, user, and membership models are typed, persisted, and consistent with the PRD
- First-launch and child profile setup flows are usable and clear
- Sharing lifecycle supports invite, activation, and removal
- Permission rules are enforced consistently
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 2: Local Data Model and CloudKit Sync

Stage summary: replace the template persistence layer with typed event storage, local-first repositories, and sync-safe CloudKit mapping.

Stage status: `Not Started`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S2-01 | Confirm the template SwiftData scaffold that will be replaced | Establish the current persistence baseline before migration work starts | None | `Done` | `Item` model and default SwiftData app wiring are present |
| S2-02 | Replace template `Item` model with typed event domain models | The MVP requires typed feed, nappy, and sleep events instead of the template item list | S0-04, S0-05, S0-08 | `Not Started` | Must match final schema decisions |
| S2-03 | Define shared event metadata model and event wrapper strategy | The tech spec requires shared metadata and a typed event wrapper | S2-02 | `Not Started` | Must cover IDs, actor metadata, timestamps, notes, and delete state |
| S2-04 | Define local persistence models for each event type | Persistence must support local-first writes and event-specific fields | S2-02, S2-03 | `Not Started` | Keep derived values out of stored source-of-truth state |
| S2-05 | Implement repository interfaces for create, edit, delete, and fetch | The rest of the app should depend on clear data APIs, not raw storage | S2-04 | `Not Started` | Include timeline/day queries and current-state queries |
| S2-06 | Implement soft-delete behavior and undo support hooks | Deletes participate in sync conflict resolution and need session recovery | S2-03, S2-05 | `Not Started` | UI undo arrives in Stage 4, but data support belongs here |
| S2-07 | Track `createdAt`, `createdBy`, `updatedAt`, `updatedBy`, and `deletedAt` consistently | Required by the PRD and sync model | S2-03, S2-04 | `Not Started` | Must be applied across all event writes |
| S2-08 | Map local models to CloudKit records | Shared data requires record schemas and stable identifier mapping | S2-04, S0-11 | `Not Started` | Should include child, membership, and event records |
| S2-09 | Implement last-write-wins conflict resolution | PRD requires event-level last-write-wins with no field-level merge in MVP | S2-08 | `Not Started` | Deletes must participate in the same conflict policy |
| S2-10 | Implement offline save, pending-sync state, retry/backoff, and eventual consistency behavior | Local-first reliability is one of the core product principles | S2-05, S2-08, S2-09 | `Not Started` | Must avoid blocking logging flows |
| S2-11 | Add persistence and sync tests | Protect storage, mapping, conflict handling, and offline recovery | S2-05, S2-06, S2-08, S2-09, S2-10 | `Not Started` | Include soft delete and recovery cases |

Exit criteria:
- Template persistence is replaced by typed event storage
- Repository APIs cover the MVP event lifecycle cleanly
- CloudKit mapping and conflict rules are defined and implemented
- Offline-first behavior preserves local usability and eventual consistency
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed where data state is surfaced
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 3: Feeding Tracking and Quick Logging

Stage summary: deliver the fastest core logging path in the app, covering breast and bottle feeds with low-friction defaults and validation.

Stage status: `Not Started`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S3-01 | Build quick-log entry points for feed actions | PRD prioritises logging in five seconds or less with one-handed use | S2-05 | `Not Started` | Entry points should be obvious from the main app surface |
| S3-02 | Implement breast-feed logging flow | Support duration-based breast feed tracking with valid side handling | S0-04, S2-05, S3-01 | `Not Started` | Should support start/end or equivalent duration capture consistent with the chosen model |
| S3-03 | Implement bottle-feed logging flow | Support bottle amount capture and final milk-type rules | S0-04, S2-05, S3-01 | `Not Started` | Validation depends on the resolved `milkType` decision |
| S3-04 | Apply sensible defaults such as current time | Reduce friction in common logging flows | S3-02, S3-03 | `Not Started` | Keep overrides easy when corrections are needed |
| S3-05 | Add inline validation for invalid feed input | Prevent impossible or incomplete entries without blocking the flow unnecessarily | S3-02, S3-03 | `Not Started` | Must align with the final event schema |
| S3-06 | Update derived feed data used by summary and live activity features | Later stages depend on accurate last-feed and interval calculations | S2-05, S3-02, S3-03 | `Not Started` | Keep derived data computed, not stored as source-of-truth state |
| S3-07 | Add tests for feed logging speed-paths and validation | Feeding is a primary MVP workflow and needs strong coverage | S3-02, S3-03, S3-04, S3-05, S3-06 | `Not Started` | Include default-time behavior and invalid input cases |

Exit criteria:
- Users can record breast and bottle feeds quickly with minimal input
- Default values reduce friction without hiding important corrections
- Validation prevents invalid feed records
- Derived feed state is available for later summary and live-activity work
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 4: Event Editing, Delete, Undo, and Empty States

Stage summary: make the core event flows safe to correct, recover, and understand even when the app has little or no data yet.

Stage status: `Not Started`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S4-01 | Build edit flows for all supported event types | PRD requires users to correct entries quickly | S2-05, S3-02, S3-03, S6-02, S7-01 | `Not Started` | Final event coverage depends on Stage 6 and Stage 7 completion |
| S4-02 | Connect UI delete actions to soft-delete data behavior | Delete behavior must align with sync-safe soft deletes | S2-06 | `Not Started` | Should not permanently remove source records |
| S4-03 | Implement immediate undo after delete | PRD explicitly requires an immediate recovery path | S2-06, S4-02 | `Not Started` | Session-window behavior should be defined clearly |
| S4-04 | Add empty states for no child, no events, and empty day views | Users need clarity when there is nothing to show yet | S1-03, S2-05 | `Not Started` | Copy should be simple and reassuring without being noisy |
| S4-05 | Add non-blocking validation and failure messaging | PRD requires clear messaging without blocking core flows | S4-01, S4-02 | `Not Started` | Should cover save failures, sync delays, and invalid edits where relevant |
| S4-06 | Add tests for edit, delete, undo, and empty-state paths | Correction and recovery flows are high-risk for regressions | S4-01, S4-02, S4-03, S4-04, S4-05 | `Not Started` | Include data recovery and no-data scenarios |

Exit criteria:
- Existing events can be edited and deleted safely
- Undo is immediate and reliable within the defined window
- Empty and low-data states are clear and usable
- Errors are surfaced simply without blocking local usage
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 5: Last Event Summary and Live Activity

Stage summary: provide a quick current-state view and surface feed recency through Live Activities.

Stage status: `Not Started`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S5-01 | Build the current-state summary surface | Users need immediate understanding of the baby's recent state | S2-05, S3-06 | `Not Started` | Keep the information density low and scan-friendly |
| S5-02 | Compute last feed time, time since last feed, feed type, and related derived values | The summary and live activity rely on accurate derived state | S3-06 | `Not Started` | Derived data should stay separate from source-of-truth storage |
| S5-03 | Implement the ActivityKit live activity for feed status | PRD and tech spec both call for Live Activities support | S0-10, S5-02 | `Not Started` | Requires full capability and entitlement setup |
| S5-04 | Refresh live activity when relevant event data changes | Live activity content must stay aligned with the latest feed data | S5-03, S2-05 | `Not Started` | Include create, edit, delete, and undo cases where appropriate |
| S5-05 | Handle unsupported device, account, and permission states gracefully | Live Activities and sync capabilities can fail independently of local logging | S5-03 | `Not Started` | Must keep local app behavior reliable even when features are unavailable |
| S5-06 | Add tests for summary derivation and live-activity update triggers | Derived logic is easy to regress if not covered | S5-01, S5-02, S5-04, S5-05 | `Not Started` | Use practical unit coverage for logic and update orchestration |

Exit criteria:
- The app surfaces a clear current-state summary for the active child
- Feed-derived values are accurate and reused consistently
- Live activity behavior is correct when available and harmless when unavailable
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 6: Nappy Tracking

Stage summary: add nappy logging with a finalised detail model that supports quick entry without invalid field combinations.

Stage status: `Complete`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S6-01 | Resolve the final nappy detail model | PRD and tech spec conflict on optional detail fields and terminology | S0-05 | `Done` | Stage 0 locked `type`, optional `intensity`, and optional `pooColor` for `.poo` and `.mixed` |
| S6-02 | Implement nappy domain and persistence models | Nappy events require their own typed storage and validation | S6-01, S2-05 | `Done` | Domain, SwiftData, and CloudKit now round-trip the agreed schema |
| S6-03 | Build nappy quick-log flow for dry, wee, poo, and mixed | PRD requires fast tracking for all nappy types | S6-02 | `Done` | Child profile now supports nappy quick logging for all four types |
| S6-04 | Show poo-specific detail fields only when appropriate | The UI must prevent invalid combinations and unnecessary input | S6-01, S6-03 | `Done` | The editor only exposes `pooColor` for `.poo` and `.mixed` |
| S6-05 | Support edit, delete, and undo for nappy events | Nappy events need the same recovery path as other event types | S6-02, S4-01, S4-02, S4-03 | `Done` | Nappy events reuse the shared event-management flow |
| S6-06 | Render nappy events correctly in timeline and summaries | Users need nappy events to scan well in daily history and state views | S6-02, S5-01, S8-01 | `Done` | Current status and recent history now show nappy events with consistent detail text |
| S6-07 | Add tests for valid and invalid nappy combinations | The nappy schema is one of the highest-risk validation areas | S6-02, S6-03, S6-04, S6-05 | `Done` | Domain, repository, CloudKit mapper, app-model, calculator, and UI coverage added |

Exit criteria:
- The nappy schema is resolved and implemented consistently across model, storage, and UI
- Users can log and edit nappy events quickly without invalid field combinations
- Nappy events display correctly in summaries and history
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 7: Sleep Tracking

Stage summary: support active and completed sleep sessions with derived durations and reliable recovery behavior.

Stage status: `Not Started`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S7-01 | Implement sleep domain and persistence models | Sleep events require open-ended sessions and derived duration behavior | S2-05 | `Complete` | Must support `endedAt` being absent while a sleep is active |
| S7-02 | Build start sleep flow | Users need a fast way to begin a sleep session | S7-01 | `Complete` | Keep the action quick and obvious |
| S7-03 | Build end sleep flow | Active sleep sessions must be closable with minimal friction | S7-01, S7-02 | `Complete` | Must prevent invalid end-before-start states |
| S7-04 | Derive sleep duration instead of storing it as source-of-truth data | The PRD and tech spec both treat duration as derived | S7-01, S7-03 | `Complete` | Derived values should be reused in summaries and timeline |
| S7-05 | Support active sleep session recovery in app state | The app needs to show and preserve an ongoing sleep session correctly | S7-02, S2-10 | `Complete` | Must behave correctly across relaunches and sync updates |
| S7-06 | Allow editing closed sleep sessions | Sleep history needs the same correction path as other events | S7-03, S4-01 | `Complete` | Editing rules for active sessions may need separate handling |
| S7-07 | Support overlapping event presentation where required | Sleep can overlap with feeds or other events in the timeline | S7-01, S8-01 | `Complete` | Timeline rules must remain readable when overlaps occur |
| S7-08 | Add tests for open-ended sessions, duration derivation, and editing | Sleep behavior includes several edge cases that need protection | S7-03, S7-04, S7-05, S7-06, S7-07 | `Complete` | Include relaunch and overlap scenarios where practical |

Exit criteria:
- Users can start and end sleep sessions reliably
- Sleep duration is derived consistently rather than stored redundantly
- Active sleep sessions recover correctly
- Sleep history can be edited safely
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Stage 8: Timeline View

Stage summary: present a day-based event history that is easy to scan for recency, gaps, and overlaps.

Stage status: `Not Started`

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| S8-01 | Build the day-based chronological timeline foundation | The timeline is the main history view for the MVP | S2-05, S3-02, S3-03, S6-02, S7-01 | `Not Started` | Should support all implemented event types |
| S8-02 | Support overlapping events visually | PRD explicitly calls out overlapping events | S8-01, S7-07 | `Not Started` | Prioritise readability over visual cleverness |
| S8-03 | Make recency and gaps easy to scan | The timeline should help caregivers understand what happened and what has not happened recently | S8-01 | `Not Started` | Should reflect the product principle of low cognitive load |
| S8-04 | Surface pending-sync state where relevant | Users need to know when local data has not synced yet | S2-10, S8-01 | `Not Started` | Avoid alarming messaging when local save succeeded |
| S8-05 | Support navigation from timeline items into edit flows | Timeline entries need to lead into correction and detail views | S4-01, S8-01 | `Not Started` | Should be consistent across event types |
| S8-06 | Add empty and loading states for timeline views | Users need clarity when a day has no events or data is still loading | S8-01 | `Not Started` | Keep states simple and easy to understand |
| S8-07 | Add tests for ordering, overlap rules, and day grouping logic | Timeline correctness depends on derived sorting and grouping behavior | S8-01, S8-02, S8-03, S8-04, S8-05, S8-06 | `Not Started` | Include timezone/day-boundary cases if applicable |

Exit criteria:
- The app shows a clear chronological day view across supported event types
- Overlaps, gaps, and recency are understandable at a glance
- Pending-sync state and empty/loading states are handled cleanly
- Timeline items navigate into edit paths consistently
- Relevant unit tests added or updated
- Shared-impact integration or UI tests added when needed
- Build and relevant tests verified
- Accessibility and one-handed-use review completed
- Error-state coverage checked against PRD recovery scenarios
- Diff reviewed for unrelated changes

## Deferred / Post-MVP

These items are intentionally excluded from active MVP delivery and should stay in backlog status unless the scope changes.

| ID | Task | Why / Scope | Dependencies | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| D-01 | Stage 9 speed improvements, timers, and widgets | PRD lists these after the MVP timeline stage | MVP stages complete | `Not Started` | Keep deferred until core logging and timeline flows are stable |
| D-02 | Stage 10 insights and trends | PRD positions insights after trustworthy event logging is complete | MVP stages complete | `Not Started` | Includes intervals, averages, and pattern recognition |
| D-03 | Multi-child support | Listed under future considerations, not MVP scope | Product decision | `Not Started` | Current access model is single-child focused |
| D-04 | Notifications and reminders | Future consideration, not required for MVP | Product decision | `Not Started` | Should not expand scope before core usage is validated |
| D-05 | Health integrations | Future consideration, not required for MVP | Product decision | `Not Started` | Requires additional data-sharing decisions |
| D-06 | Cross-platform support | Future consideration, not required for MVP | Product decision | `Not Started` | Keep native iOS as the only active platform for MVP |

## Open Decisions

| ID | Decision | Impacted Stages | Current State | Notes |
| --- | --- | --- | --- | --- |
| O-01 | Is `milkType` optional or required for bottle feeds? | Stage 0, Stage 2, Stage 3, Stage 5 | `Blocked` | PRD and tech spec disagree |
| O-02 | What is the canonical nappy detail schema? | Stage 0, Stage 2, Stage 6, Stage 8 | `Done` | Stage 0 locked `type`, optional `intensity`, optional `pooColor`, and no `PooConsistency` in the MVP |
| O-03 | What typed model should represent `Child`, `User`, and `Membership` in the technical design? | Stage 0, Stage 1, Stage 2 | `Blocked` | PRD defines records, tech spec does not type them |
| O-04 | Should the tech-spec package list be implemented as real local packages, targets, or a simpler staged structure? | Stage 0, Stage 1, Stage 2 | `Not Started` | Choose the simplest structure that still supports clean boundaries |
| O-05 | What is the delete undo window and exact UX pattern? | Stage 2, Stage 4 | `Not Started` | PRD requires immediate undo but does not define the interaction details |

## Risks / Blockers

| ID | Risk / Blocker | Affected Stages | Status | Notes |
| --- | --- | --- | --- | --- |
| R-01 | Spec mismatches could cause rework if implementation starts before schema decisions are locked | Stage 0, Stage 2, Stage 3, Stage 6 | `Active` | Resolve schema conflicts first |
| R-02 | CloudKit and sharing setup require Apple account and dashboard configuration outside the repo | Stage 0, Stage 1, Stage 2, Stage 5 | `Active` | Repo work alone cannot unblock full sync/sharing delivery |
| R-03 | The current repo is still the Xcode template, so architecture work must happen before feature delivery accelerates | Stage 0, Stage 1, Stage 2 | `Active` | Avoid layering feature code onto the starter template structure |
| R-04 | Multi-caregiver sync and removal flows can create edge cases around data visibility and conflict resolution | Stage 1, Stage 2 | `Active` | Needs careful testing with multiple accounts and devices |
| R-05 | Live Activities depend on capability setup, device support, and account state that may not be available in all test environments | Stage 5 | `Active` | Must fail gracefully without blocking local app usage |

- [ ] Complete
