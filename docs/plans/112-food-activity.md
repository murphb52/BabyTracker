# 112 - Food Activity and Shared Presets

## Summary

Add Food as a first-class point-in-time activity. Each entry records one food, the consumed amount, a flexible unit, and time. Food coexists with Bottle Feed and participates in logging, history, timelines, summaries, shared sync, backup, caregiver notifications, onboarding, and the Feed Live Activity.

## Plan

1. Add the Food domain model, units, validation, log/update use cases, recent-name lookup, and first-class `BabyEvent` integration.
2. Add child-owned Food presets with explicit save, edit, reorder, soft delete, deterministic ordering, and exact-combination deduplication.
3. Persist and synchronize Food events and presets through SwiftData and the shared CloudKit zone, including cleanup and sync-state paths.
4. Add Food logging/editing and preset-management interfaces with starter names, unit-specific amounts, previews, accessibility, and the coral `fork.knife` presentation style.
5. Add Food to every general activity surface, Today and Trends summaries, caregiver notifications, native backup/restore, and the Live Activity's latest Feed selection.
6. Preserve existing milk-feed summary calculations and Huckleberry import behavior, migrate existing visibility preferences once, and verify the complete test suite and CloudKit schema.

## Acceptance Criteria

- A caregiver can create, edit, delete, restore, filter, and view Food events everywhere other activities appear.
- A caregiver can explicitly save a full Food combination as a child preset, then edit, reorder, or remove shared presets without changing event history.
- Food events and presets round-trip through local persistence, CloudKit sync, and version 2 Nest backup/restore.
- Today shows Food count, latest entries, and an hourly cumulative chart; Trends shows daily counts and averages.
- Food can become the Live Activity's latest Feed event without changing breast/bottle interval metrics.
- Existing users see Food enabled once after upgrading and can subsequently disable it normally.
- Relevant previews compile, focused tests pass, and `scripts/validate.sh` succeeds.

- [ ] Complete
