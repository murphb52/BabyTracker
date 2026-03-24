# Architecture Review: Baby Tracker iOS

## Context
First-pass senior architecture review focused on highest-confidence improvements.
Pre-production app, so significant structural changes are acceptable.

---

## What the Codebase Gets Right

Before the problems: the foundation is genuinely solid.

- Dependency direction is correct: Feature → Sync → Persistence → Domain ✓
- Domain layer is pure — zero framework imports beyond Foundation ✓
- No circular dependencies ✓
- Repository pattern properly abstracts persistence behind protocols ✓
- No SwiftData/CloudKit leaking into Domain or Feature ✓
- Presentation logic in Feature, not in views ✓
- Protocol-oriented at the right boundaries ✓
- Dependency injection via initializers, no service locators ✓

The architecture is not broken. The issues are accumulation and clarity problems, not fundamental design failures.

---

## Identified Problems

### Problem 1: AppModel is a God Object (1,324 lines)

**What it does:** routing, child CRUD, event logging, timeline navigation, sync coordination, sharing, undo logic, live activity dispatch.

**Why it's a problem:**
- Violates SRP: many unrelated reasons to change
- Hard to test individual concerns in isolation
- Every new feature adds to a single growing file
- Navigation state, event state, sync state, and profile state all tangled together
- AppModel is the single most likely file to cause merge conflicts

**Better shape:**
Split into focused `@Observable` objects, each owning one concern:
- `ChildManagementModel` — create, archive, restore, select children
- `EventLoggingModel` — log, update, delete, undo events for the active child
- `TimelineModel` — timeline day navigation, day page state
- `SharingModel` — share sheet, caregiver management, leave share

AppModel itself becomes a thin coordinator that holds these sub-models and routes between them.

**Early refactor candidate:** YES — highest priority.

---

### Problem 2: ChildProfileRepository Has Too Many Responsibilities (23 methods)

**What it does:** local user identity, CloudKit user linking, child selection preference, child CRUD, CloudKit context, membership CRUD, user identity lookups, data purging.

**Why it's a problem:**
- A 23-method protocol is a fat interface — violates ISP
- Unrelated concerns: "which child is selected in the UI" is a local preference, not a child profile operation
- "Save local user" and "link to CloudKit record" are identity concerns, not profile concerns
- Every implementation (or test double) must implement all 23 methods even if it only needs 3

**Better shape:**
- `ChildRepository` — child CRUD + CloudKit context (5–6 methods)
- `UserIdentityRepository` — local user save/load/link (3 methods)
- `MembershipRepository` — membership CRUD (5–6 methods)
- `ChildSelectionStore` — selected child ID preference (2 methods, probably just UserDefaults directly)

SwiftDataChildProfileRepository can still implement all of these if that's practical, but the protocols should be separate.

**Early refactor candidate:** YES — second priority. Splitting the protocol forces clearer ownership and simplifies test doubles.

---

### Problem 3: Stage1/ Naming Is Misleading

**What it is:** All 28 production view files live in `Baby Tracker/App/Stage1/`. Two stub files in BabyTrackerFeature (`Stage1AppModel.swift`, `Stage1Route.swift`) are 3-line typealiases.

**Why it's a problem:**
- Implies temporary or in-progress work — this is the real app
- New contributors will not know what Stage1 means
- Stage1AppModel and Stage1Route in Feature are dead weight (typealiases to the real thing)
- Misleading structure makes it harder to understand what's production code

**Better shape:**
- Rename `Stage1/` → `Views/` or organize as `Views/Home/`, `Views/Timeline/`, `Views/Profile/`, `Views/Editors/`
- Delete `Stage1AppModel.swift` and `Stage1Route.swift` from BabyTrackerFeature — they add nothing
- Rename `Stage1ErrorBannerView.swift` → `ErrorBannerView.swift`

**Early refactor candidate:** YES — cheap, high-clarity win.

---

### Problem 4: BabyTrackerFeature Owns Repository Protocols It Shouldn't Define

**What happens:** Repository protocols (`ChildProfileRepository`, `EventRepository`, `SyncStateRepository`) are defined in `BabyTrackerPersistence`. `BabyTrackerFeature` depends on `BabyTrackerPersistence` directly to consume them.

**Why it's a problem:**
- The Feature layer now has a compile-time dependency on the Persistence package
- This means Feature knows about persistence-layer types and concerns
- Clean architecture says the domain/application layer should define the repository interfaces; data layer implements them

**Better shape:**
Move repository *protocols* to `BabyTrackerDomain`. The implementations stay in `BabyTrackerPersistence`.
- Feature would then only depend on Domain (plus Sync for the sync engine)
- Persistence depends on Domain (as it already does) and implements Domain-defined protocols
- This is the canonical Dependency Inversion: the high-level policy (Domain) defines the interface; the low-level detail (Persistence) implements it

**Early refactor candidate:** MEDIUM — architecturally correct but requires touching multiple packages. Do this during or after the repository split.

---

### Problem 5: AppContainer Mixes Production DI with Test Scenario Seeding (311 lines)

**What it does:** Creates the real dependency graph AND has a large `seed()` method that creates test scenarios (5 named scenarios with full fake data).

**Why it's a problem:**
- Test/preview concerns bleed into the production composition root
- AppContainer will grow whenever a new scenario is needed
- Makes the DI setup harder to scan — real init logic is buried under seeding

**Better shape:**
- Extract seeding into a `PreviewScenarioFactory` or `DevelopmentScenarioSeeder` type
- AppContainer becomes a focused composition root (probably ~80–100 lines)

**Early refactor candidate:** LOW — works fine as-is, but makes AppContainer harder to maintain over time.

---

### Problem 6: CloudKitSyncEngine Is Large but Cohesive (864 lines)

**What it does:** Launch sync, incremental sync, share creation, participant management, share acceptance, pending invite queries, record mapping coordination.

**Why it's a problem (maybe):**
- 864 lines is large
- But it is all CloudKit sync logic — not mixed concerns

**Better shape (if needed):**
- `CloudKitSharingCoordinator` — share creation, accept, remove participant (currently ~200 lines of methods)
- `CloudKitChangeProcessor` — fetch/push record zone changes (~400 lines)
- `CloudKitSyncEngine` becomes an orchestrator over these

**Early refactor candidate:** LATER — not urgent. The existing file is large but not confusingly mixed.

---

## Package Ownership Recommendations

| Package | Should Own |
|---|---|
| `BabyTrackerDomain` | Entities, value objects, business rules, domain errors, *repository protocols* (after refactor) |
| `BabyTrackerPersistence` | SwiftData models, repository implementations, model container setup |
| `BabyTrackerSync` | CloudKit client abstraction, sync engine, record mapper, share acceptance |
| `BabyTrackerFeature` | Observable models, presentation state, screen states, calculators, routing |
| App target | Views, composition root (AppContainer), CloudKit delegates, live activity manager |

---

## Prioritized Recommendations

### Do Now

1. **Rename Stage1/ and delete Stage1 stubs** — cheap, no logic change, immediate clarity improvement
2. **Split ChildProfileRepository into focused sub-protocols** — reduces fat interface, forces explicit dependency on only what each consumer needs
3. **Begin splitting AppModel** — extract TimelineModel first (self-contained), then EventLoggingModel

### Do Soon

4. **Move repository protocols to BabyTrackerDomain** — completes the Dependency Inversion principle, decouples Feature from Persistence
5. **Extract seeding from AppContainer** — clean up the composition root

### Do Later

6. **Split CloudKitSyncEngine** — extract CloudKitSharingCoordinator
7. **Review ChildWorkspaceTabView (331 lines)** — consider a tab-level coordinator for sheet state

---

## Step-by-Step First-Pass Implementation Sequence

### Step 1: Rename Stage1/ and clean up Stage1 stubs

**What to change:**
- Rename `Baby Tracker/App/Stage1/` → `Baby Tracker/App/Views/` (or organize into subdirectories: `Views/Home/`, `Views/Timeline/`, `Views/Editors/`, `Views/Profile/`, `Views/Sharing/`)
- Delete `Stage1AppModel.swift` from BabyTrackerFeature
- Delete `Stage1Route.swift` from BabyTrackerFeature
- Rename `Stage1ErrorBannerView.swift` → `ErrorBannerView.swift`
- Update Xcode project references

**Why it helps:** Removes confusion about what is production code. Makes the folder structure speak clearly.

**What should be true afterwards:** No file or folder named `Stage1` exists. All view files have meaningful names and locations. `AppRoute` is used directly — no typealiases.

**What to avoid:** Don't reorganize view logic while renaming. This is a pure rename pass.

---

### Step 2: Split ChildProfileRepository into focused sub-protocols

**What to change:**
Define three protocols in place of one:
- `ChildRepository` — `loadAllChildren`, `loadActiveChildren`, `loadArchivedChildren`, `loadChild(id:)`, `saveChild`, `loadCloudKitChildContext`, `saveCloudKitChildContext`, `purgeChildData`
- `UserIdentityRepository` — `loadLocalUser`, `saveLocalUser`, `linkLocalUser(toCloudKitUserRecordName:)`, `loadUsers(for:)`, `saveUser`
- `MembershipRepository` — `loadMemberships(for:)`, `saveMembership`, `saveCloudKitMembership`, `removeLegacyPlaceholderCaregivers`
- Move `loadSelectedChildID` / `saveSelectedChildID` to a `ChildSelectionStore` — these are UI preference storage, not domain repository concerns

Update `SwiftDataChildProfileRepository` to conform to all of them (no logic changes needed — just protocol conformances).

Update `AppModel` to accept these as separate injected dependencies.

**Why it helps:** Each call site now depends only on the methods it actually uses. Test doubles become trivial (3–5 methods each). ISP violation is resolved.

**What should be true afterwards:** No single protocol has more than ~8 methods. Each protocol represents a single coherent responsibility. `AppModel` may grow its init signature — that's acceptable.

**What to avoid:** Don't change persistence logic. Don't move these protocols to Domain yet (that's Step 4). Just split the protocol.

---

### Step 3: Extract TimelineModel from AppModel

**What to change:**
Create `TimelineModel: Observable` in BabyTrackerFeature:
- Move all timeline-related state: `selectedTimelineDay`, timeline page state, timeline navigation week data
- Move methods: `showPreviousTimelineDay()`, `showNextTimelineDay()`, `jumpTimelineToToday()`, `showTimelineDay(_:)`
- Move private helpers: timeline week calculation, day page state building

AppModel holds a `TimelineModel` instance and delegates timeline-related calls to it.

**Why it helps:** ~200–300 lines move out of AppModel. TimelineModel is self-contained — it needs only events (already fetched) and a date. Minimal entanglement.

**What should be true afterwards:** `TimelineModel` is independently testable. AppModel is 900–1000 lines (not 1,324). Timeline navigation has a clear home.

**What to avoid:** Don't change how views observe state yet. Don't move event fetching — just move day navigation and page building logic.

---

### Step 4: Move repository protocols to BabyTrackerDomain

**What to change:**
- Move `ChildRepository`, `UserIdentityRepository`, `MembershipRepository`, `SyncStateRepository`, `EventRepository` protocols to `BabyTrackerDomain`
- Remove them from `BabyTrackerPersistence`
- Update `BabyTrackerPersistence` to import `BabyTrackerDomain` (already does this)
- Update `BabyTrackerFeature`'s Package.swift to remove the `BabyTrackerPersistence` dependency (Feature should now only depend on Domain + Sync)

**Why it helps:** Correct dependency inversion. Feature layer is now decoupled from Persistence. The high-level policy (Domain) defines interfaces; the detail (Persistence) implements them.

**What should be true afterwards:** `BabyTrackerFeature`'s Package.swift lists: `.product(name: "BabyTrackerDomain", ...)` and `.product(name: "BabyTrackerSync", ...)` — no more Persistence dependency.

**What to avoid:** Don't move implementation files. Don't move SwiftData models. Only move protocol definitions.

---

## Top 5 Obvious Refactors

1. **Split AppModel** — extract TimelineModel, EventLoggingModel, ChildManagementModel, SharingModel
2. **Split ChildProfileRepository** — separate child, identity, membership, and selection concerns
3. **Rename Stage1/** — rename folder and delete stub typealiases
4. **Move repository protocols to Domain** — complete the DIP
5. **Extract seeding from AppContainer** — create PreviewScenarioFactory

---

## Top 5 Anti-Patterns to Look For

1. **AppModel accumulation** — any new feature being added directly to AppModel as another method/property
2. **ChildProfileRepository growth** — any new persistence concern added to the 23-method protocol instead of a focused new protocol
3. **Stage1 patterns repeating** — new folders or files with development-phase names instead of domain names
4. **Feature → Persistence coupling** — any new type in BabyTrackerFeature importing BabyTrackerPersistence for concrete types (not protocols)
5. **CloudKitSyncEngine scope creep** — adding non-sync logic (e.g., business rules or UI coordination) to the sync engine

---

## Recommended First Week of Refactor Work

| Day | Task |
|---|---|
| Day 1 | Rename Stage1/ → Views/, delete Stage1AppModel.swift + Stage1Route.swift, update Xcode references. Build and verify. |
| Day 2 | Define ChildRepository, UserIdentityRepository, MembershipRepository protocols. Update SwiftDataChildProfileRepository to conform to all three. |
| Day 3 | Update AppModel to take split repositories as separate init parameters. Update AppContainer. All tests pass. |
| Day 4 | Extract TimelineModel from AppModel. Move state, navigation methods, private helpers. |
| Day 5 | Move repository protocols to BabyTrackerDomain. Remove BabyTrackerPersistence dependency from BabyTrackerFeature. Verify build and tests. |
