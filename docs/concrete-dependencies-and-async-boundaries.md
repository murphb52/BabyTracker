# Concrete Dependencies And Async Boundaries

## What changed

`AppModel` no longer depends directly on the concrete `CloudKitSyncEngine`.

Instead, it now depends on the `CloudKitSyncControlling` protocol. This lets
tests provide a small fake implementation instead of constructing the full sync
engine and waiting on real CloudKit-oriented behavior.

This change was driven by a failing `AppModel` unit test. The test was meant to
verify UI-facing sync banner behavior, but it was indirectly exercising the real
sync engine through `UnavailableCloudKitClient()`. That made the test slow and
timing-sensitive even though the behavior under test lived at the `AppModel`
boundary.

## Why this matters

Depending on a concrete implementation at the presentation layer makes tests
harder to control.

Problems this creates:

- "Unit" tests quietly become integration tests.
- Tests inherit infrastructure timing and failure modes they do not care about.
- Callers are forced to construct more real system than they actually need.
- Refactors become riskier because high-level code is coupled to a low-level
  implementation detail.

Using a focused protocol at the boundary keeps the dependency explicit while
letting tests model only the behavior they need.

## Follow-up work

We should do a pass through the app and look for other places where high-level
types depend on concrete implementations when they really only need a narrow
behavioral contract.

Areas to look for:

- presentation-layer types that directly store concrete repositories, engines,
  managers, or framework adapters
- tests that must build large real objects just to control one small behavior
- "unit" tests that are slow because they cross into persistence, networking, or
  CloudKit behavior unnecessarily

The goal is not to add protocols everywhere. The goal is to add boundaries where
they solve a real substitution problem.

## Async guidance

This change also exposed another issue: `refreshSyncStatus()` previously kicked
off work in a fire-and-forget task, which forced the test to poll for eventual
state.

That is a sign the API boundary is weaker than it should be.

Preferred guidance:

- use `async` functions when the caller needs to know when work is finished
- reserve closure or fire-and-forget task patterns for truly detached work
- prefer awaiting completion over polling shared state in tests

In practice, this means we should favor `async/await` over callback-style or
spawned-task boundaries when the operation has a meaningful completion point.

## Practical rule

When a caller needs to wait for a result, model that explicitly in the API.

When a test needs elaborate polling, sleeps, or long timeouts, first check
whether the production API is hiding completion behind a concrete dependency or
a fire-and-forget async boundary.
