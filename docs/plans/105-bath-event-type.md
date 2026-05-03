# 105 - Bath Event Type

## Summary
Add `Bath` as a first-class user event across the existing event system, using the same end-to-end shape as `Nappy`, `Sleep`, `Bottle Feed`, and `Breast Feed`: dedicated domain model, persistence/sync mapping, presentation helpers, editor flow, event visibility/filtering, timeline rendering, and Summary Trends support.

Before implementation starts:
1. Create `docs/plans/105-bath-event-type.md` with this plan and a `- [ ] Complete` checkbox.
2. Create a GitHub issue for the feature and reference the new plan doc from the issue.

## Key Changes
1. Domain and event plumbing
- Add `BathEvent` in `BabyTrackerDomain` with `metadata`, `usedShampoo`, and `usedSoap`.
- Extend `BabyEvent` and `BabyEventKind` with `.bath`.
- Add bath create/update use cases following the existing `Log*UseCase` / `Update*UseCase` pattern.
- Add any bath-specific validation as simple domain rules only; time is the event `occurredAt`, and both booleans are optional-style flags represented as `Bool`.

2. Persistence and sync
- Add a `StoredBathEvent` SwiftData model and include it in `BabyTrackerModelStore`.
- Extend `SwiftDataEventRepository` to save, load, soft-delete, day-filter, and timeline-load bath events alongside the existing event tables.
- Extend CloudKit config and mapping with a new bath record type plus `shampooUsed` / `soapUsed` fields.
- Update CloudKit mutable field keys, record creation, record decoding, and any sync-summary/pending-change paths that enumerate event record types.
- Preserve backward compatibility by only adding a new record/table type; existing event decoding behavior remains unchanged.

3. UI and presentation
- Add bath title/detail/icon/color handling in the same helpers that currently drive other event types:
  `BabyEventPresentation`, `BabyEventStyle`, event card state, timeline item state, filter chips, visibility settings, onboarding/customize-events copy, and preview/sample data.
- Add Bath to Home Quick Log as a normal event button and expose a `BathEditorSheetView` plus corresponding `ChildEventSheet` / `EventActionPayload` cases for quick-log and edit flows.
- Show bath detail text consistently as the existing cards do, e.g. time plus a concise shampoo/soap summary when true.
- Update Home recent cards, Home today timeline, All Events, grouped timeline sheets, and timeline day/week views so bath uses its bath-specific styling everywhere colors/icons are already applied.
- Keep Live Activity logic unchanged except for any safe internal exhaustiveness updates; Bath must not appear in the widget UI or feed live activity content.

4. Filtering and summaries
- Add Bath to event-type visibility and All Events event-type filtering with no extra bath-only filter section.
- Update event history pills, empty states, and filter chips so Bath behaves like the other top-level event kinds.
- Extend trend aggregation with daily bath counts and average daily baths.
- Add a Bath chart to Summary `Trends` using the existing grouped-by-range day bucketing and chart card styling.
- Do not add Bath to Summary `Today`.
- Keep advanced/day-based summary behavior aligned with the current architecture: Bath contributes to overall event/activity totals but does not require a new Today metric card unless an existing generic total already includes all events.

## Public Interfaces / Types
- Add `BabyEventKind.bath`
- Add `BabyEvent.bath(BathEvent)`
- Add `BathEvent`
- Add `EventActionPayload.editBath(...)`
- Add `ChildEventSheet.quickLogBath` and `ChildEventSheet.editBath(...)`
- Add `StoredBathEvent`
- Add `TrendsSummaryData.dailyBath` and `avgDailyBaths` or equivalent bath trend fields

## Test Plan
1. Domain tests
- Bath event creation/update succeeds with valid metadata and booleans.
- Event filters include/exclude Bath correctly through `eventTypes`.

2. Persistence/sync tests
- Repository round-trips Bath events.
- Timeline/day loading includes Bath in the correct sort order.
- CloudKit mapping round-trips Bath records and leaves existing record mappings unchanged.

3. Feature/UI state tests
- Presentation helpers return Bath title, detail text, icon, and colors.
- Event card and timeline view-state builders produce Bath edit payloads.
- Summary trends calculator produces correct daily bath counts and averages.
- Existing Today summary tests remain unchanged for non-Bath behavior.

4. UI / preview / regression checks
- Bath can be created from Home Quick Log and saved.
- Bath appears on Home, All Events, and Timeline views.
- All Events filtering by Bath works.
- Trends shows a Bath chart; Today does not.
- Live Activity widget still excludes Bath.

## Assumptions
- Bath is a point-in-time event, not a duration event.
- Bath creation is exposed through Home Quick Log and event customization flows, because that is the app’s primary creation path.
- Bath uses a repo-matched default bath icon and a distinct aqua/teal palette, applied anywhere `BabyEventStyle` and related helpers already drive event visuals.
- No bath-specific Today summary card, live activity surface, or extra filter subsection will be added.

- [x] Complete
