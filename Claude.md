# Claude.md

## Purpose

This codebase is a Swift application organized around **clean architecture**, with **Swift Packages** used as architectural boundaries. The goal is to keep the system modular, testable, understandable, and easy to change over time.

This document defines the engineering expectations for all new code, refactors, and reviews.

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

### 3. Comments should add value
- Add comments where they explain **why**, intent, constraints, or non-obvious tradeoffs.
- Do not add comments that merely restate the code.
- Public APIs and important business rules should be documented clearly.
- Use comments to explain boundaries, invariants, and architectural decisions when helpful.

### 4. Prefer value types where appropriate
- Favor `struct` over `class` unless reference semantics are required.
- Use `final class` when reference semantics are needed and inheritance is not intended.
- Avoid unnecessary shared mutable state.

### 5. Make invalid states hard to represent
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

## Testing Expectations

### 1. Test behavior, not implementation trivia
- Focus tests on business rules, use cases, mapping rules, and critical presentation state transformations.
- Avoid brittle tests tied to private implementation details.

### 2. Domain logic should be easy to test
- Domain use cases should not require UI frameworks, network access, or databases to test.
- Prefer protocol-based seams for external dependencies.

### 3. Keep test doubles simple
- Use lightweight fakes, spies, or mocks only where they add clarity.
- Do not over-engineer test infrastructure.

### 4. Add regression tests for bugs
- When fixing a bug, add or update a test that proves the failure mode is covered.

---

## SwiftUI and Presentation Guidance

- Keep views as simple rendering and event forwarding units.
- Avoid placing business logic directly in SwiftUI views.
- View models or presentation adapters should shape state for display, not own unrelated application concerns.
- If a view model starts handling navigation, formatting, orchestration, persistence, and business rules together, split it.
- Prefer small observable types scoped to a specific screen or flow.

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

---

## Definition of Done for New Code

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
