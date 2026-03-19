# 005 Stage 3: Feeding Tracking and Quick Logging

## Summary

Implement Stage 3 on the existing child profile screen. Add quick-log flows for breast and bottle feeds, save them through the local-first event pipeline, refresh derived feed data immediately, and keep the UI simple enough for one-handed use.

## Plan

1. Update the feeding schema and supporting data layers.
   - Add `.both` to `BreastSide`.
   - Make breast-feed side optional.
   - Require breast-feed end times to be later than start times.
   - Preserve SwiftData and CloudKit round-tripping for nil, left, right, and both side values.
2. Extend permissions and app state for feed logging.
   - Add explicit `.logEvent` access checks.
   - Inject `EventRepository` into `AppModel`.
   - Add `logBreastFeed(durationMinutes:endTime:side:)` and `logBottleFeed(amountMilliliters:occurredAt:milkType:)`.
3. Add derived feed summary support.
   - Introduce `FeedSummary`, `FeedSummaryCalculator`, and `FeedingSummaryViewState`.
   - Compute the latest feed kind, last logged time, and today’s feed count from stored events.
4. Add quick-log UI to the child profile screen.
   - Show “Quick Log” buttons for breast and bottle feeds.
   - Present sheet-based forms with sensible defaults.
   - Disable save for invalid duration or amount values and show inline validation copy.
   - Show a minimal “Feeding” section with an empty state or the latest derived values.
5. Add and update automated coverage.
   - Extend domain, repository, and UI tests for the new quick-log flows.
   - Add coverage for feed summary derivation and CloudKit breast-feed mapping.
   - Run `./scripts/validate.sh`.

- [x] Complete
