# AppModel Architecture Gap Analysis

Date: 2026-04-03

## Scope
This analysis compares the current repository architecture with the target in `swiftui_architecture_with_diagram.md`.

## Current state summary

1. **Strong package decomposition already exists** (`Domain`, `Feature`, `Persistence`, `Sync`) and the app target acts as composition root through `AppContainer`.
2. **Feature still depends on infrastructure packages directly** (`BabyTrackerPersistence`, `BabyTrackerSync`) rather than depending only on domain abstractions.
3. **`AppModel` remains very large and multi-responsibility** (1,542 lines) and combines:
   - app routing/session state
   - read-side repository orchestration
   - sync orchestration
   - feature-level state shaping for timeline/home/history
   - import/export orchestration
   - transient UI banners, undo, and sheet state

## Gap vs target architecture

### 1) Dependency direction gap (high priority)
**Target:** `Feature -> Domain` only.

**Current:** `Feature -> Domain + Persistence + Sync` in package manifest, and direct infrastructure imports in `AppModel`.

**Impact:** Feature-level types know infrastructure details, making replacement/testing harder and coupling package boundaries.

### 2) AppModel responsibility gap (high priority)
**Target:** thin app coordinator focused on app/session/navigation state.

**Current:** `AppModel` owns many domains simultaneously (child profile loading, timeline derivation, sync banners, import/export workflows, event write flows), plus infrastructure-triggering logic.

**Impact:** high merge pressure, larger regression blast radius, and slower feature-level iteration.

### 3) Read-side use case extraction gap (high priority)
**Target:** read assembly happens behind domain use cases, then mapped in feature.

**Current:** `refresh(selecting:)` path and helpers still load and assemble repository data directly inside `AppModel`.

**Impact:** read rules are not easily testable as independent business/application workflows.

### 4) Presentation mapper boundary gap (medium priority)
**Target:** feature mappers shape view state from use case results.

**Current:** timeline/page/strip assembly and several display derivations live inside `AppModel`.

**Impact:** app coordinator remains responsible for display shaping details.

### 5) Import/export orchestration placement gap (medium priority)
**Target:** business/data-flow decisions in use cases; UI state transitions in presentation.

**Current:** parsing + duplicate handling flow control + execution state are concentrated in `AppModel`.

**Impact:** hard to evolve import/export flows independently from core app session state.

## High-level refactor areas to reach target

## 1. Fix package dependency direction
- Remove direct `BabyTrackerPersistence` and `BabyTrackerSync` dependency from `BabyTrackerFeature`.
- Expose only domain protocols/use-case interfaces to feature.
- Keep concrete persistence/sync wiring in app composition root.

## 2. Split AppModel into coordinator + focused feature coordinators
- Keep one app-level coordinator for route/session/navigation/transient app UI.
- Move feature-specific orchestration into focused observable models (timeline, child workspace, import/export).
- Avoid creating wrappers without clear state ownership.

## 3. Extract read-side application use cases in Domain
- Add use cases for loading app session/initial route and loading child workspace snapshots.
- Move selection fallback and workspace load decisions out of `AppModel`.
- Unit test these use cases directly in domain tests.

## 4. Introduce explicit feature mappers
- Map domain workspace snapshots into screen/view states in `BabyTrackerFeature`.
- Keep timeline strip/page calculations in dedicated mapper/calculator types unless they are true domain rules.

## 5. Isolate sync-facing behavior behind dedicated service seams
- Keep sync refresh trigger decisions in app coordinator.
- Push non-UI sync policy/notification derivations into use cases/services that are not tied to app state container size.

## 6. Decompose import/export into separate flows
- Separate import parsing/tagging/execution orchestration from app-wide state container.
- Keep `AppModel` owning only presentation state handoff and routing-level transitions.

## Suggested sequence (safe migration)
1. Dependency direction cleanup (`Feature -> Domain` only at package boundary).
2. Read-side use case extraction for `refresh(selecting:)`.
3. Feature mapper extraction for timeline/workspace state.
4. Import/export flow extraction.
5. Optional final split of remaining app coordinator concerns if still oversized.

## Progress against target
- **What is already aligned:** package modularization, composition root pattern, extensive domain use case coverage on write path.
- **What is furthest from target:** Feature dependency direction and `AppModel` scope/size.
- **Overall:** foundational architecture exists, but boundary enforcement and orchestration decomposition are only partially complete.
