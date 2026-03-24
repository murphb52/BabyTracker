# BabyTracker Refactor Plan

## Goals

Refactor the codebase toward:

-   clean architecture
-   SOLID principles
-   protocol-oriented design where it genuinely helps
-   small, focused types
-   small, simple functions
-   strong package boundaries
-   minimal Apple framework leakage into business logic
-   fewer god objects
-   clearer UI ownership
-   easier testing and maintenance

This is a pre-production app, so the plan can be bold where needed.

------------------------------------------------------------------------

## Guiding Rules

1.  One type, one clear reason to change
2.  One protocol, one clear responsibility
3.  Prefer one main protocol conformance per implementation type where
    practical
4.  Use cases live in Domain
5.  Feature depends on Domain, not Persistence
6.  Persistence and Sync are infrastructure
7.  App target is the composition root, not the business layer
8.  If a file grows hard to explain, split it
9.  If a type starts orchestrating too much, move behavior into use
    cases
10. Names should reflect domain or responsibility, never build history

------------------------------------------------------------------------

# Phase 1 - Naming Cleanup

Remove all Stage{x} naming patterns (Stage1, Stage2, Stage3 etc).

Search patterns: Stage0 Stage1 Stage2 Stage3 Stage4 Stage5 Stage6 Stage7
Stage8 Stage9 Stage`\d+`{=tex}

Rename to domain or responsibility-based names.

Success signal: No Stage naming remains in the codebase.

------------------------------------------------------------------------

# Phase 2 - Split AppModel

Extract: - TimelineModel - EventLoggingModel - ChildContextModel -
SharingModel

Each model should: - own one area of state - delegate business flow to
use cases

------------------------------------------------------------------------

# Phase 3 - Introduce Use Cases

Examples: - LoadTimeline - SelectChild - LogFeedingEvent -
ArchiveChild - LoadSharingParticipants

Use cases hold business flow logic.

------------------------------------------------------------------------

# Phase 4 - Split ChildProfileRepository

Create focused protocols: - ChildRepository - UserIdentityRepository -
MembershipRepository

Create focused implementations: - SwiftDataChildRepository -
SwiftDataUserIdentityRepository - SwiftDataMembershipRepository

Separate: - ChildSelectionStore

------------------------------------------------------------------------

# Phase 5 - Move Repository Protocols to Domain

Move abstractions: - ChildRepository - MembershipRepository -
EventRepository

Feature depends only on Domain.

------------------------------------------------------------------------

# Phase 6 - Sync Isolation

Ensure CloudKit concerns remain in Sync.

Avoid CloudKit types leaking into Domain.

------------------------------------------------------------------------

# Phase 7 - Composition Root Cleanup

Simplify AppContainer.

Separate: - preview setup - dev seeding

------------------------------------------------------------------------

# Top 10 Refactor Actions

1.  Remove Stage{x} naming
2.  Clarify UI ownership
3.  Split AppModel
4.  Introduce use cases
5.  Split ChildProfileRepository
6.  Split concrete persistence implementations
7.  Move repository protocols into Domain
8.  Remove Feature -\> Persistence dependency
9.  Isolate CloudKit concerns
10. Simplify AppContainer

------------------------------------------------------------------------

# Anti-Patterns to Avoid

-   splitting protocols but keeping giant implementations
-   replacing one god object with several medium god objects
-   business logic in views
-   Feature depending on Persistence
-   Domain depending on frameworks
-   vague utility dumping grounds

------------------------------------------------------------------------

# First 4 Weeks

Week 1: - rename Stage{x} - extract TimelineModel

Week 2: - introduce first use cases - split ChildProfileRepository

Week 3: - split persistence implementations - move protocols into Domain

Week 4: - inspect Sync - clean AppContainer

------------------------------------------------------------------------

End of plan.
