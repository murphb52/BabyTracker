# AGENTS.md

## Purpose
This document defines how agents and contributors should work in this SwiftUI project.

The default approach is:

- keep solutions simple
- optimize for readability over cleverness
- prefer explicit code over compact abstractions
- make small, safe, atomic changes
- keep the project in a passing state before and after each commit

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

When choosing between “shorter” and “clearer,” choose clearer.

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

## SwiftUI-specific guidance

### Views
- Keep `body` readable.
- Break large views into smaller subviews when it improves understanding.
- Do not extract subviews too early if the extraction makes navigation harder.
- Prefer simple view composition over deeply generic reusable components.

### State
- Keep state ownership clear.
- Prefer the simplest property wrapper that fits the use case.
- Avoid spreading state across too many layers without a good reason.
- Derive values simply and explicitly.

### Naming
- Use names that describe intent, not implementation details.
- Prefer full words over abbreviations unless the abbreviation is standard.
- Method and property names should make most comments unnecessary.

### Architecture
- Follow the existing project structure unless there is a strong reason to change it.
- Prefer straightforward boundaries over elaborate patterns.
- Introduce protocols, coordinators, or abstractions only when they solve a real and current problem.
- Keep one top-level type definition per Swift file whenever practical. Do not group multiple structs, enums, protocols, or classes into the same file unless the relationship is unusually tight and splitting them would make the code harder to follow.

## Tests

### General
- Add or update tests when behavior changes.
- Keep tests readable and focused on behavior.
- Avoid overly coupled tests that break on harmless refactors.

### Expectations
Tests should:

- clearly communicate what is being verified
- cover the intended behavior, not incidental implementation details
- remain easy to maintain

When fixing a bug:

- add a test that fails before the fix when practical
- then implement the fix

## Comments
Comments are welcome when they explain **why** something exists or why a decision was made.

Do not add comments that simply restate what the code already says.

Good uses of comments:

- explaining a non-obvious tradeoff
- documenting a workaround
- capturing an important constraint from SwiftUI or platform behavior
- clarifying intent when the “why” would otherwise be hard to infer

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

## Preferred change style

Prefer this:

- simple implementation
- explicit naming
- small focused files and methods
- comments that explain why
- targeted tests
- atomic commits

Avoid this:

- clever abstractions
- mixing unrelated changes
- speculative architecture
- large commits with multiple concerns
- committing without running tests

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

## Final note
When in doubt, choose the more readable, more explicit, lower-complexity approach.

This project values maintainability and steady progress over cleverness.
