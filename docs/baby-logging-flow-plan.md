# Baby Logging Flow — Implementation Plan

## Context
The four logging flows (bottle, nappy, breastfeeding, sleep) need a UX overhaul for speed, one-handed use, and consistency. Current editors use a raw `DatePicker` with no quick time presets. Breastfeeding has no live timer. Sleep has no smart start suggestions. Nappy has a single shared `intensity` field where the spec wants separate per-type volumes.

Branch: `claude/baby-logging-flow-742Zm` (already exists, forked from `master`; remote `origin/main` is the target)

---

## 1. Shared Component — QuickTimeSelectorView

**New file:** `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/QuickTimeSelectorView.swift`

- Pill-button row: **Now · 5m ago · 10m ago · 15m ago · 30m ago · Custom**
- Selecting a preset updates `selection: Binding<Date>` to `Date() - offset`
- Tapping **Custom** reveals an inline `DatePicker` (same style as existing editors)
- Highlight selected preset with `Color.accentColor` (match existing quick-amount button pattern in `BottleFeedEditorSheetView`)
- Accessibility identifiers: `time-preset-now`, `time-preset-5m`, …, `time-preset-custom`

Reuse pattern: existing `LazyVGrid`/`HStack` pill-button style in `BottleFeedEditorSheetView.swift:94–122`.

---

## 2. Bottle Feed — Add Quick Time Presets

**Modify:** `Views/BottleFeedEditorSheetView.swift`

- Replace `DatePicker("Time", …)` (line 44–49) with `QuickTimeSelectorView(selection: $occurredAt)`
- No other changes needed (quick amounts, milk type unchanged)

---

## 3. Nappy — Per-Type Volumes + Quick Time Presets

### 3a. New Domain Enum
**New file:** `Packages/BabyTrackerDomain/Sources/BabyTrackerDomain/NappyVolume.swift`
```swift
public enum NappyVolume: String, CaseIterable, Codable, Sendable {
    case light, medium, heavy
}
```

### 3b. Domain Model Changes
**Modify:** `NappyEvent.swift`
- Replace `intensity: NappyIntensity?` with `peeVolume: NappyVolume?` and `pooVolume: NappyVolume?`

**Modify:** `NappyEntry.swift`
- Same field replacement; update validation logic accordingly

### 3c. Persistence
**Modify:** `Models/StoredNappyEvent.swift`
- Add `var peeVolumeRawValue: String?` and `var pooVolumeRawValue: String?` (optional, default nil)
- Keep old `intensityRawValue` column (stop reading it; SwiftData lightweight migration handles new optional columns automatically)

**Modify:** `SwiftDataEventRepository.swift` — `saveNappy` and `mapNappy` functions
- Map `peeVolume`/`pooVolume` ↔ `peeVolumeRawValue`/`pooVolumeRawValue`

### 3d. Use Cases
**Modify:** `UseCases/LogNappyUseCase.swift` — Input struct: replace `intensity` with `peeVolume`, `pooVolume`
**Modify:** `UseCases/UpdateNappyUseCase.swift` — same

### 3e. Feature Layer
**Modify:** `AppModel.swift` — `logNappy` and `updateNappy` signatures → replace `intensity:` with `peeVolume:` and `pooVolume:`

**Modify:** `EventActionPayload.swift` → `.editNappy` case: replace `intensity:` with `peeVolume:` and `pooVolume:`

**Modify:** `EventCardViewState.swift` → nappy branch: pass `peeVolume`/`pooVolume` into action payload

**Modify:** `ChildEventSheet.swift` → `.editNappy` case: same field update

**Modify:** `Views/ChildWorkspaceTabView.swift` → `.editNappy` sheet: pass updated fields

### 3f. UI
**Modify:** `Views/NappyEditorSheetView.swift` — complete rework of form body:
- Replace `DatePicker` with `QuickTimeSelectorView(selection: $occurredAt)`
- Replace single intensity picker with two conditional volume pickers:
  - **Pee volume** (Light/Medium/Heavy): shown when type is `.wee` or `.mixed`
  - **Poo volume** (Light/Medium/Heavy): shown when type is `.poo` or `.mixed`
- Rename "Wee" → "Pee" in all UI labels (keep domain rawValue `.wee`)
- Poo color remains conditional on `.poo` / `.mixed` (existing logic in `NappyEntry.supportsPooColor`)
- `.presentationDetents([.large])` may be needed due to increased content

---

## 4. Breastfeeding — Timer + Manual Modes

### 4a. Domain Model Changes
**Modify:** `BreastFeedEvent.swift`
- Add `leftDurationSeconds: Int?` and `rightDurationSeconds: Int?` (optional, no validation required)
- Keep existing `side: BreastSide?` for backward compat; derive from which durations are set when editing

**Modify:** `Models/StoredBreastFeedEvent.swift`
- Add `var leftDurationSeconds: Int?` and `var rightDurationSeconds: Int?` (optional, default nil)

**Modify:** `SwiftDataEventRepository.swift` — `saveBreastFeed` and `mapBreastFeed`

### 4b. Use Cases
**Modify:** `UseCases/LogBreastFeedUseCase.swift` — add `leftDurationSeconds: Int?` and `rightDurationSeconds: Int?` to Input
**Modify:** `UseCases/UpdateBreastFeedUseCase.swift` — same; update `BreastFeedEvent.updating(…)` signature

### 4c. Feature Layer
**Modify:** `AppModel.swift` — `logBreastFeed` and `updateBreastFeed` add optional `leftDurationSeconds` and `rightDurationSeconds`

**Modify:** `EventActionPayload.swift` → `.editBreastFeed` case: add `leftDurationSeconds: Int?`, `rightDurationSeconds: Int?`

**Modify:** `EventCardViewState.swift`, `ChildEventSheet.swift`, `ChildWorkspaceTabView.swift` — propagate new fields

### 4d. UI — Complete Rewrite
**Modify:** `Views/BreastFeedEditorSheetView.swift`

**Mode selector** (top of form): `Picker` with `.segmented` style — "Timer" / "Manual"

**Timer mode:**
- `@State var leftElapsed: TimeInterval = 0`, `rightElapsed: TimeInterval = 0`
- `@State var leftRunning: Bool = false`, `rightRunning: Bool = false`
- `@State var sessionStartedAt: Date = Date()`
- `timer` publisher via `Timer.publish(every: 1, on: .main, in: .common).autoconnect()` — `.onReceive` increments whichever side is running
- Starting one side pauses the other
- Layout: `HStack` with two large pill buttons ("Left" / "Right"); timer labels below each (mm:ss)
- Save captures: `startedAt` = `sessionStartedAt`, `endedAt` = now, `leftDurationSeconds`, `rightDurationSeconds`, derives `side` from which timers ran
- `.presentationDetents([.medium])`

**Manual mode:**
- `QuickTimeSelectorView(selection: $endTime)` for time
- Total duration: text field + quick presets (5, 10, 15 min) — existing pattern
- Per-boob toggle: "Add per-side breakdown" toggle; when on shows left duration (min) + right duration (min) text fields

---

## 5. Sleep — Manual Mode with Smart Presets + End Time Presets

### 5a. AppModel — Sleep Start Suggestions
**Modify:** `AppModel.swift` — add method:
```swift
public func sleepStartSuggestions(for childID: UUID) -> [(label: String, date: Date)]
```
Loads last bottle, breast feed, nappy from `eventRepository.loadTimeline(for:)`, returns up to 3 suggestions with labels like "Last bottle at 4:45 PM", "Last feed at 2:10 PM", "Last nappy at 3:20 PM".

### 5b. ChildEventSheet + ChildWorkspaceTabView
**Modify:** `ChildEventSheet.swift`
- `.startSleep` case → add `suggestions: [(label: String, date: Date)]`
- `.startSleep` static factory passes them from AppModel

**Modify:** `Views/ChildWorkspaceTabView.swift` — compute and pass suggestions when presenting `.startSleep`

### 5c. UI
**Modify:** `Views/SleepEditorSheetView.swift`

**Mode selector:** Picker "Timer" / "Manual" at top

**Timer mode** (matches current start/end behavior):
- Start mode: "Start Sleep" button (existing logic, no change)
- End mode: shows live elapsed time (time interval since `startedAt`) refreshed by a timer publisher

**Manual mode:**
- **Start time**: horizontal scroll of suggestion buttons (smart presets) + "Custom" that reveals `DatePicker`
- **End time**: `QuickTimeSelectorView(selection: $endedAt)` — Now/5/10/15/30 mins ago + Custom
- Existing validation (end > start) preserved

`SleepEditorSheetView.init` gains `suggestions: [(label: String, date: Date)]` parameter (empty by default for edit mode).

`presentationDetents([.large])` for manual mode due to increased content.

---

## Critical Files Summary

| File | Change |
|------|--------|
| `BabyTrackerDomain/.../NappyVolume.swift` | **NEW** |
| `BabyTrackerFeature/.../Views/QuickTimeSelectorView.swift` | **NEW** |
| `BabyTrackerDomain/.../NappyEvent.swift` | intensity → peeVolume/pooVolume |
| `BabyTrackerDomain/.../NappyEntry.swift` | same |
| `BabyTrackerDomain/.../BreastFeedEvent.swift` | add left/rightDurationSeconds |
| `BabyTrackerDomain/.../UseCases/LogNappyUseCase.swift` | updated Input |
| `BabyTrackerDomain/.../UseCases/UpdateNappyUseCase.swift` | updated Input |
| `BabyTrackerDomain/.../UseCases/LogBreastFeedUseCase.swift` | updated Input |
| `BabyTrackerDomain/.../UseCases/UpdateBreastFeedUseCase.swift` | updated Input |
| `BabyTrackerPersistence/.../Models/StoredNappyEvent.swift` | add pee/pooVolumeRawValue |
| `BabyTrackerPersistence/.../Models/StoredBreastFeedEvent.swift` | add left/rightDurationSeconds |
| `BabyTrackerPersistence/.../SwiftDataEventRepository.swift` | updated mapping |
| `BabyTrackerFeature/.../AppModel.swift` | updated signatures + sleepStartSuggestions |
| `BabyTrackerFeature/.../EventActionPayload.swift` | updated cases |
| `BabyTrackerFeature/.../EventCardViewState.swift` | updated nappy/breastfeed branches |
| `BabyTrackerFeature/.../ChildEventSheet.swift` | updated cases |
| `BabyTrackerFeature/.../Views/ChildWorkspaceTabView.swift` | updated sheet presentations |
| `BabyTrackerFeature/.../Views/BottleFeedEditorSheetView.swift` | QuickTimeSelectorView |
| `BabyTrackerFeature/.../Views/NappyEditorSheetView.swift` | major rework |
| `BabyTrackerFeature/.../Views/BreastFeedEditorSheetView.swift` | complete rewrite |
| `BabyTrackerFeature/.../Views/SleepEditorSheetView.swift` | major rework |
| `BabyTrackerFeature/.../BabyEventPresentation.swift` | update nappy detail text |

---

## Assumptions
- **Nappy volume** is qualitative (Light/Medium/Heavy), not mL — consistent with parent UX patterns
- **Dry nappy** type kept (domain has it; useful even though spec lists Pee/Poo/Mixed)
- **Breastfeeding timer** runs while sheet is open (live — no background timer / Live Activity needed)
- Existing `intensityRawValue` column left in `StoredNappyEvent` (no migration needed — SwiftData handles new optional columns automatically)

---

## Verification
1. Build the project — all Swift compiler errors must be resolved (the domain/persistence/feature layers form a compile-time dependency chain)
2. Run existing test suite (`swift test` or Xcode test runner) — no regression
3. Manual smoke test each log flow:
   - Bottle: tap preset time → correct date; custom → DatePicker appears
   - Nappy Wee: pee volume shown, poo volume hidden, poo color hidden
   - Nappy Poo: poo volume shown, pee volume hidden, poo color shown
   - Nappy Mixed: both volumes shown, poo color shown
   - Breastfeed Timer: start left, elapsed ticks; start right, left pauses; save stores durations
   - Breastfeed Manual: preset time, total duration, per-side toggle
   - Sleep Manual: smart presets show last events; end time presets work
   - Sleep Timer: start sleep → end sleep shows elapsed counter
4. Push to `claude/baby-logging-flow-742Zm` and open PR against `main`
