# AGENTS.md

## About this file

`AGENTS.md` and `Claude.md` contain identical content. They exist side by side because different tools look for different filenames. If you update one, update the other to the same content. This file is the source of truth; `Claude.md` is a mirror.

---

## Purpose

This document defines how agents and contributors should work in this SwiftUI project, and the engineering expectations for all new code, refactors, and reviews.

The default approach is:

- keep solutions simple
- optimize for readability over cleverness
- prefer explicit code over compact abstractions
- make small, safe, atomic changes
- keep the project in a passing state before and after each commit

---

## Core principles

### 1. Prefer simple over complex
Choose the simplest design that solves the problem well.

A few extra lines of clear code are better than a dense abstraction that is harder to understand, debug, or change later.

Avoid introducing:

- unnecessary indirection
- premature generalization
- custom frameworks or helpers without a clear need
- clever one-liners when straightforward code is easier to read

### 2. Readability is the priority
Write code for the next person reading it.

That means:

- clear names
- small focused types and methods
- predictable control flow
- minimal hidden behavior
- explicit data flow when possible

When choosing between "shorter" and "clearer," choose clearer.

### 3. Commit atomically
Commits should be small and focused.

Each commit should:

- do one logical thing
- be easy to review
- be easy to revert
- leave the project building and tests passing

Avoid mixing unrelated refactors with feature work or bug fixes in the same commit.

For multi-step work, agents should commit incrementally as each logical slice is completed and verified.

Do not wait until the end of a long implementation to create one large commit if the work can be separated safely into smaller passing commits.

### 4. Do not commit broken builds
Before committing, make sure:

- the project builds
- existing tests pass
- any new tests added for the change pass

A commit should represent a healthy project state.

---

## Core Architectural Rules

### 1. Prefer package boundaries for architecture
- Use **Swift Packages** to separate architectural layers and major features.
- Dependencies should point inward toward stable abstractions.
- Avoid leaking implementation details across package boundaries.
- Shared code should live in a dedicated package only when it represents a real shared concept, not as a dumping ground.

### 2. Enforce clean architecture
Organize code around clear layers with explicit responsibilities:

- **Domain**
  - Business rules
  - Entities
  - Value objects
  - Use cases
  - Domain protocols
- **Data**
  - Repository implementations
  - API clients
  - Persistence details
  - DTO mapping
- **Presentation**
  - SwiftUI views / view models / presentation adapters
  - UI state shaping
  - User interaction handling

Rules:
- UI must not depend directly on persistence or networking details.
- Data layer must not contain presentation logic.
- Domain should be the most stable layer and should not know about UI or framework-heavy implementation details.
- Prefer dependency inversion through protocols defined at the appropriate boundary.

### 3. Prefer protocol-oriented design
- Use protocols to define behavior at boundaries.
- Depend on abstractions, not concretions.
- Keep protocols small and focused.
- Avoid "fat protocols" that collect unrelated responsibilities.
- Use protocol composition when it improves clarity.
- Do not create protocols without a real boundary, testing need, or substitution use case.

### 4. Keep functions and types small
- Prefer small, focused functions with a single responsibility.
- Prefer simple types with one clear purpose.
- If a type starts accumulating unrelated responsibilities, split it.
- If a file becomes difficult to scan, separate concerns into smaller files.
- Avoid god classes, god objects, and god view models.
- Favor composition over oversized inheritance trees.

### 5. Follow SOLID principles

#### Single Responsibility Principle
- Every type should have one reason to change.
- Separate orchestration, mapping, persistence, networking, and business logic.

#### Open/Closed Principle
- Extend behavior through composition and new conforming types rather than modifying stable core logic unnecessarily.

#### Liskov Substitution Principle
- Conforming types should behave consistently with the abstraction they implement.

#### Interface Segregation Principle
- Prefer many small protocols over a single large one.

#### Dependency Inversion Principle
- High-level policies should not depend on low-level details.
- Details should depend on abstractions.

---

## Code Style Expectations

### 1. Prefer simple functions
- Write straightforward functions with clear inputs and outputs.
- Minimize hidden state.
- Prefer pure functions where practical.
- Keep branching shallow when possible.
- Extract complex decision logic into named helpers.

### 2. Prefer explicit naming
- Names should communicate intent clearly.
- Favor domain language over vague technical names.
- Avoid generic names like `Manager`, `Helper`, `Service`, or `Utility` unless the responsibility is truly precise and unavoidable.
- Prefer full words over abbreviations unless the abbreviation is standard.
- Method and property names should make most comments unnecessary.

### 3. Prefer value types where appropriate
- Favor `struct` over `class` unless reference semantics are required.
- Use `final class` when reference semantics are needed and inheritance is not intended.
- Avoid unnecessary shared mutable state.

### 4. Make invalid states hard to represent
- Model domain concepts explicitly.
- Prefer strong types and value objects over loose primitive passing.
- Validate at boundaries.
- Centralize business invariants in the domain layer.

---

## Dependency Rules

### Allowed dependency direction
Preferred dependency flow:

**Presentation -> Domain**
**Data -> Domain**

Implementation details may depend on lower-level frameworks, but the core business layer should remain isolated from them.

### Dependency injection
- Use initializer injection by default.
- Avoid service locators and hidden global dependencies.
- Default to passing only the dependencies a type actually needs.
- Build objects at composition roots, not deep inside feature logic.

### Framework isolation
- Isolate Apple frameworks, networking libraries, persistence libraries, and third-party SDKs behind boundaries.
- Avoid spreading framework-specific logic across the codebase.
- Keep framework coupling at the edges.

---

## Package Guidance

Use Swift Packages deliberately.

### Suggested package shape
This is an example, not a strict template:

- `App`
- `Feature*` packages
- `Domain`
- `Data`
- `DesignSystem`
- `SharedKernel` only if truly justified

### Package rules
- Each package should have a clear reason to exist.
- Avoid circular dependencies under all circumstances.
- Feature packages should expose minimal public API.
- Keep internal implementation internal.
- Do not create broad shared packages that become dependency magnets.
- Prefer feature-local ownership before promoting code to shared modules.

---

## Working agreement for agents

### Before making changes
Understand the local context before editing.

Check:

- the surrounding SwiftUI view or feature structure
- naming patterns already used in the project
- existing tests and previews
- whether a simpler change can solve the problem without introducing new abstractions

### While making changes
Keep edits narrow and intentional.

Prefer:

- updating existing code instead of adding layers
- local reasoning over project-wide complexity
- small helper methods only when they improve clarity
- composition that remains easy to follow

Avoid broad refactors unless they are necessary for the task.

When a task spans multiple logical steps, stop at each completed slice, verify it, and create a commit before continuing.

### Before committing
Verify the change is safe.

At minimum:

1. build the project
2. run relevant tests
3. run the full test suite when the change has shared impact
4. review the diff for unrelated edits
5. confirm the commit is atomic

If tests fail, fix them before committing.

---

## SwiftUI and Presentation Guidance

### Views
- Keep `body` readable.
- Break large views into smaller subviews when it improves understanding.
- Do not extract subviews too early if the extraction makes navigation harder.
- Prefer simple view composition over deeply generic reusable components.
- Keep views as simple rendering and event forwarding units.
- Avoid placing business logic directly in SwiftUI views.

### State
- Keep state ownership clear.
- Prefer the simplest property wrapper that fits the use case.
- Avoid spreading state across too many layers without a good reason.
- Derive values simply and explicitly.
- View models or presentation adapters should shape state for display, not own unrelated application concerns.
- If a view model starts handling navigation, formatting, orchestration, persistence, and business rules together, split it.
- Prefer small observable types scoped to a specific screen or flow.

### Naming
- Use names that describe intent, not implementation details.
- Prefer full words over abbreviations unless the abbreviation is standard.
- Method and property names should make most comments unnecessary.

### Architecture
- Follow the existing project structure unless there is a strong reason to change it.
- Prefer straightforward boundaries over elaborate patterns.
- Introduce protocols, coordinators, or abstractions only when they solve a real and current problem.
- Keep one top-level type definition per Swift file whenever practical. Do not group multiple structs, enums, protocols, or classes into the same file unless the relationship is unusually tight and splitting them would make the code harder to follow.

---

## Data Layer Guidance

- Repository implementations should translate between domain and external systems.
- DTOs should not leak into the domain or presentation layers.
- Mapping logic should be explicit and testable.
- Network clients should do networking.
- Repositories should coordinate data access.
- Persistence components should handle storage concerns only.

---

## Domain Layer Guidance

- Domain models should reflect business meaning, not storage or API shape.
- Use cases should express clear application actions.
- Business rules should live in the domain layer whenever possible.
- Domain protocols should model needed capabilities in business terms.

Example style:
- `FetchUserProfile`
- `SaveSettings`
- `CalculatePricing`
- `ValidateCheckout`

Prefer use cases that do one thing well.

---

## Testing Expectations

### General
- Add or update tests when behavior changes.
- Keep tests readable and focused on behavior.
- Avoid overly coupled tests that break on harmless refactors.
- Focus tests on business rules, use cases, mapping rules, and critical presentation state transformations.

### Domain logic should be easy to test
- Domain use cases should not require UI frameworks, network access, or databases to test.
- Prefer protocol-based seams for external dependencies.

### Keep test doubles simple
- Use lightweight fakes, spies, or mocks only where they add clarity.
- Do not over-engineer test infrastructure.

### Expectations
Tests should:

- clearly communicate what is being verified
- cover the intended behavior, not incidental implementation details
- remain easy to maintain

When fixing a bug:

- add a test that fails before the fix when practical
- then implement the fix

---

## Refactoring Rules

Refactor when you notice:
- a type growing too large
- a file with multiple unrelated concerns
- repeated logic across features
- ambiguous ownership
- presentation code knowing too much about data details
- domain logic buried in UI or infrastructure code
- protocols that are too broad
- functions that are difficult to explain simply

When in doubt, split code earlier rather than later.

---

## Anti-Patterns to Avoid

- God classes
- Massive view models
- Massive repository types
- Shared "utils" dumping grounds
- Static global state without strong justification
- Hidden dependencies
- Business logic in views
- DTOs leaking across layers
- Package boundaries that exist in name only
- Protocols with many unrelated methods
- Over-abstracting trivial code
- Comment noise that restates obvious code
- Clever abstractions
- Mixing unrelated changes
- Speculative architecture
- Large commits with multiple concerns
- Committing without running tests

---

## Comments

Comments are welcome when they explain **why** something exists or why a decision was made.

Do not add comments that simply restate what the code already says.

Good uses of comments:

- explaining a non-obvious tradeoff
- documenting a workaround
- capturing an important constraint from SwiftUI or platform behavior
- clarifying intent when the "why" would otherwise be hard to infer
- explaining boundaries, invariants, and architectural decisions

Public APIs and important business rules should be documented clearly.

---

## TODOs

TODOs are useful when there is a known gap that is intentionally left for later.

Use TODOs when:

- something is intentionally not built yet
- follow-up work is known and expected
- a temporary solution is in place

Write TODOs so they are actionable and specific.

Good example:

```swift
// TODO: Replace this mock data source once persistence is wired into onboarding.
```

Bad example:

```swift
// TODO: Fix this
```

---

## Planning documents

When planning work, create a document in:

```
/docs/plans
```

### Requirements

Each plan must:

- be clearly written and easy to follow
- describe the goal and approach in simple terms
- avoid unnecessary complexity or speculative design
- be numbered so progress can be tracked

Example naming:

- `001-onboarding-flow.md`
- `002-data-persistence.md`

Numbering should be sequential and unique.

### Completion tracking

At the end of every plan document, include a completion checkbox:

```
- [ ] Complete
```

When the plan has been fully implemented, update it to:

```
- [x] Complete
```

This ensures it is always clear what is finished and what is still in progress.

### Expectations

- Plans should be created before implementing non-trivial work.
- Implementation should follow the plan closely unless a simpler approach is discovered.
- If the approach changes meaningfully, update the plan.

---

## Definition of Done

New code should:
- respect package boundaries
- keep domain logic independent from UI and infrastructure
- use focused protocols where boundaries matter
- prefer small, simple functions
- avoid oversized types
- use dependency injection
- include meaningful comments where needed
- be testable in isolation where practical
- align with SOLID principles
- leave the codebase cleaner than it was before

---

## Commit checklist

Before creating a commit, confirm all of the following:

- [ ] The change is focused on one logical concern.
- [ ] The code favors clarity over cleverness.
- [ ] The simplest reasonable solution was chosen.
- [ ] New or changed behavior is covered by tests when appropriate.
- [ ] Relevant tests pass.
- [ ] The project builds successfully.
- [ ] Comments explain why, not what.
- [ ] TODOs are specific and intentional.
- [ ] The diff contains no unrelated edits.

---

## Review Checklist

When writing or reviewing code, ask:

- Does this type have a single clear responsibility?
- Is this the right package and boundary?
- Are dependencies pointing in the correct direction?
- Can this logic be split into smaller functions or types?
- Is a protocol useful here, or is it unnecessary abstraction?
- Is business logic placed in the domain layer?
- Are comments explaining intent rather than narrating code?
- Are framework details isolated at the edges?
- Will this be easy to test and maintain in six months?

---

## Preferred Mindset

Build small, composable, well-named pieces.

Choose clarity over cleverness.
Choose boundaries over convenience.
Choose composition over accumulation.
Choose simple code over impressive code.
Choose maintainability over short-term speed.

When something starts getting too large, split it.

When in doubt, choose the more readable, more explicit, lower-complexity approach.

This project values maintainability and steady progress over cleverness.
