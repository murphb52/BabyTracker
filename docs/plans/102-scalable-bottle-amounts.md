# 102 — Scalable Bottle Amounts

## Goal

Improve the bottle amount picker so it adapts to the parent's patterns and preferences instead of showing the same fixed quick-select amounts for everyone.

Two related improvements are included:

1. **Smart suggestions** — Show 1–2 amounts at the top of the picker based on what the parent usually logs at the current time of day over the past seven days.
2. **Customisable quick-select amounts** — Let the parent edit which amounts appear in the quick-select grid, replacing the hardcoded defaults.

Reference: GitHub issue #231, owner comment clarifying scope.

---

## Approach

### Smart suggestions

A new `FetchSmartBottleAmountsUseCase` loads the last seven days of the child's bottle feed timeline, filters events whose time-of-day falls within ±2 hours of the current time, counts frequency per amount, and returns the top two most common amounts. These are shown at the top of the Amount section with a "Suggested" label. If there is no history in the window, the section is hidden.

The use case is called in `AppModel.smartBottleAmounts()` and the result is carried in the `.quickLogBottleFeed(smartSuggestions:)` enum case, following the same pattern as sleep suggestions.

### Customisable amounts

`Child` gains a `customBottleAmountsMilliliters: [Int]?` property. When `nil`, the existing defaults are used. When set, the quick-select grid shows those amounts instead.

Amounts are persisted in `StoredChild` as a JSON string and synced via CloudKit.

A customise button (pencil icon) appears in the Amount section header when a save callback is wired up. Tapping it presents `BottleAmountCustomizerView` — a sheet where the parent can add and remove amounts (displayed in their preferred unit). Saving calls back to `AppModel.updateBottleQuickAmounts(_:)`.

### Files changed

**Domain**
- `Child.swift` — add `customBottleAmountsMilliliters: [Int]?`
- New `FetchSmartBottleAmountsUseCase.swift`
- New `SaveBottleQuickAmountsUseCase.swift`

**Persistence**
- `StoredChild.swift` — add `customBottleAmountsJSON: String?`
- `SwiftDataChildRepository.swift` — encode/decode custom amounts

**Sync**
- `CloudKitRecordMapper.swift` — sync custom amounts field

**Feature**
- `ChildEventSheet.swift` — `.quickLogBottleFeed(smartSuggestions: [Int])`
- `BottleFeedEditorSheetView.swift` — smart suggestions row, custom amounts, edit button
- New `BottleAmountCustomizerView.swift`
- `AppModel.swift` — `smartBottleAmounts()` and `updateBottleQuickAmounts(_:)`
- `ChildWorkspaceTabView.swift` — wire up smart suggestions and custom amounts
- `OnboardingFirstEventStepView.swift` — update enum case usage

**Tests**
- New `FetchSmartBottleAmountsUseCaseTests.swift`

---

## Steps

1. [x] Create plan document
2. [ ] Domain: add `customBottleAmountsMilliliters` to `Child`
3. [ ] Domain: `FetchSmartBottleAmountsUseCase`
4. [ ] Domain: `SaveBottleQuickAmountsUseCase`
5. [ ] Persistence: `StoredChild` + `SwiftDataChildRepository`
6. [ ] Sync: `CloudKitRecordMapper`
7. [ ] Feature: update `ChildEventSheet`, `AppModel`, and wiring
8. [ ] Feature: update `BottleFeedEditorSheetView`
9. [ ] Feature: `BottleAmountCustomizerView`
10. [ ] Tests: `FetchSmartBottleAmountsUseCaseTests`
11. [ ] Build and test

---

- [ ] Complete
