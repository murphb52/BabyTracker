# Liquid Glass App Audit — Nest (Baby Tracker)

**Generated:** 2026-04-18  
**Rubric:** `/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/docs/liquid-glass-app-audit-guide.md`  
**Platform target:** iOS 26+  
**Audit method:** Static code analysis of 79 SwiftUI view files across 5 Swift packages

---

## Executive Summary

- The app has a solid native foundation: `NavigationStack`, standard `TabView`, system `.sheet` and `.confirmationDialog`, and system `List` are used correctly throughout. This is the right starting point.
- **Zero Liquid Glass APIs are in use.** No `glassEffect`, `GlassEffectContainer`, `glassEffectID`, `safeAreaBar`, `ToolbarSpacer`, `matchedTransitionSource`, or `backgroundExtensionEffect` appear anywhere in the codebase.
- The Timeline screen builds a completely custom navigation header using `.regularMaterial` + a manual `Divider()` border — this duplicates system bar behavior and actively fights the platform's chrome system.
- The Events screen builds a second custom bar (filter pills row) using a manual background and `Divider()` separator — same anti-pattern.
- Error and sync indicator overlays use absolute `.overlay(alignment: .top)` placement rather than the safe-area-aware APIs the platform provides.
- The Summary screen applies a `.thinMaterial` + white stroke + shadow stack to every card — a mild blur stack applied broadly rather than selectively.
- No source-continuity exists for any sheet or navigation push. Sheets appear from the bottom with no visual connection to the control that triggered them.
- No search exists anywhere. The Events filter is a custom sheet and custom pill bar instead of `.searchable`.

---

## What the App Is Already Doing Well

### Navigation and top-level structure
- **`AppRootView`** correctly wraps everything in a single `NavigationStack` — no custom push/pop illusions.
- **`ChildWorkspaceTabView`** uses a standard `TabView` with `.tabItem` for all five tabs. Tabs are top-level sections only (Home, Events, Timeline, Summary, Profile). None are overloaded with screen-specific CTAs.
- **`AppSettingsView`** and all child detail screens use `NavigationLink` with system back behavior. Back gesture works normally on all push destinations.
- **`ChildPickerView`** uses a `navigationTitle("Nest")` through the standard stack — correct.

### Sheets and dialogs
- All event logging modals (`BreastFeedEditorSheetView`, `BottleFeedEditorSheetView`, `SleepEditorSheetView`, `NappyEditorSheetView`) use system `.sheet` — correct presentation style for this amount of content.
- `TimelineScreenView` uses `.confirmationDialog` for delete confirmation — exactly the right API for this use case, not a custom overlay.
- `SummaryScreenView` uses `.popover(isPresented:)` with `.presentationCompactAdaptation(.popover)` for the date picker — good; this adapts correctly across size classes.
- `ChildWorkspaceTabView` presents `CloudKitShareSheetView` as a `.sheet` — correct.

### Accessibility groundwork
- `InteractiveOnboardingView` reads `@Environment(\.accessibilityReduceMotion)` and skips slide animations entirely — good.
- `BabyEventStyle` uses `UIColor { traits in ... }` for all event-type colors, providing full light/dark mode adaptation.
- Decorative icons throughout use `.accessibilityHidden(true)`.
- `.accessibilityIdentifier` is applied to interactive controls throughout, enabling automated UI testing.

### Safe area insets for transient banners
- `AppRootView` uses `.safeAreaInset(edge: .bottom)` for both the undo-delete banner and the transient message banner — this is the correct API. These banners participate in safe area layout, so the tab bar and content inset correctly.

### Onboarding motion direction awareness
- `InteractiveOnboardingView` tracks `isGoingBack` and applies asymmetric slide transitions in the correct direction, with a fallback to `.opacity` when Reduce Motion is enabled.

---

## Easy Wins Being Missed

### 1. Timeline custom header → system toolbar placements
**File:** `TimelineScreenView.swift`, `pinnedDayNavigationHeader`

The day navigation header (prev/next buttons, weekday selector, week title) is a custom `VStack` with `.background(.regularMaterial)` and a manual `Divider()` at the bottom. Moving the day navigation controls to `.toolbar { }` placements would eliminate the custom bar entirely, let content scroll under the real navigation bar, and pick up the system's scroll-edge behavior for free.

**Why low risk:** Toolbar placements are stable SwiftUI APIs. Testable in Simulator with no external dependencies.

### 2. Events filter → `.searchable` + filter tokens
**File:** `EventHistoryView.swift`, `filterPillsBar`

The filter pills bar is a manually built horizontal scroll sitting between the nav bar and the list. SwiftUI's `.searchable` modifier would place the search field where users expect it, handle keyboard dismissal correctly, and automatically participate in the navigation bar's scroll-edge behavior. Active filter pills could become system search tokens.

**Why low risk:** `EventHistoryViewModel` already owns the filter state — the view change is mostly replacing the custom bar with `.searchable`.

### 3. Error and sync overlays → `.safeAreaBar(edge: .top)`
**File:** `AppRootView.swift` lines 56–81

The error banner and sync indicator use `.overlay(alignment: .top)` with fixed `.padding(.top, 8)`. These don't participate in safe area layout — they can overlap the dynamic island or status bar on certain devices. `.safeAreaBar(edge: .top)` is specifically designed for this pattern.

**Why low risk:** The visual result is nearly identical; the correctness improvement is significant.

### 4. `ToolbarSpacer` for toolbar grouping
**File:** `ChildWorkspaceTabView.swift` lines 99–122

The workspace toolbar places a single action item per active tab. As the app grows, using `ToolbarSpacer` to create deliberate visual grouping between related and unrelated actions would be a free hierarchy win.

**Why low risk:** Additive-only change. Can be applied incrementally.

### 5. `matchedTransitionSource` + `.navigationTransition(.zoom)` for event cards
**Files:** `EventHistoryView.swift`, `ChildWorkspaceTabView.swift`

When a user taps an event card, a sheet appears from the bottom with no visual connection to the row. A zoom transition anchored to the card would make the sheet feel like it expanded from the row rather than appearing from nowhere — one of the biggest perceived-quality improvements available.

**Why medium risk:** iOS 18+ APIs. App already targets iOS 26, so these are available. Risk is implementation time, not compatibility.

### 6. Simplify Summary card backgrounds
**File:** `SummaryScreenView.swift`, `cardBackground`

The `cardBackground` computed property stacks `.thinMaterial` + a white stroke + a shadow, applied to every card. The white stroke vanishes in dark mode. Removing it and reducing the shadow makes cards more resilient with no structural change.

**Why low risk:** Visual-only change, no behavioral impact.

---

## Places Fighting the System

### HIGH severity

#### 1. Custom navigation header in TimelineScreenView
**File:** `TimelineScreenView.swift` lines 104–189  
**Symbol:** `pinnedDayNavigationHeader`

```swift
private var pinnedDayNavigationHeader: some View {
    VStack(alignment: .leading, spacing: 14) {
        // week title, prev/next buttons, weekday strip...
    }
    .padding(.horizontal, 12)
    .padding(.top, 10)
    .padding(.bottom, 12)
    .background(.regularMaterial)           // ← manually mimicking system bar material
    .overlay(alignment: .bottom) {
        Divider()                           // ← manually mimicking system bar separator
    }
}
```

This custom bar:
- Sits below the system navigation bar, creating two stacked chrome regions.
- Uses `.regularMaterial` to mimic bar appearance, but does not participate in the system's scroll-edge behavior.
- Has a hard `Divider()` separator that is always visible — the system fades this based on scroll position.
- Prevents content from flowing under the navigation bar naturally.
- Blocks any future `backgroundExtensionEffect()` usage.

**Verdict:** Actively fighting the system. Should be replaced with toolbar placements and a proper nav title/subtitle.

---

#### 2. Custom filter pills bar in EventHistoryView
**File:** `EventHistoryView.swift` lines 73–105  
**Symbol:** `filterPillsBar`

```swift
private var filterPillsBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) { ... }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    .background(Color(.secondarySystemGroupedBackground))    // ← custom bar background
    .overlay(alignment: .bottom) { Divider() }              // ← manual separator
}
```

Same anti-pattern as the Timeline header — a custom bar with manual background and `Divider()`. The filter pills are activated from the toolbar filter button but the active state lives in a custom bar rather than integrating with the toolbar or search system.

**Verdict:** Actively fighting the system.

---

### MEDIUM severity

#### 3. Blur stack on Summary card backgrounds
**File:** `SummaryScreenView.swift` lines 864–872  
**Symbol:** `cardBackground`

```swift
private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.thinMaterial)                                      // ← material
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)  // ← white border on material
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 8) // ← shadow on material
}
```

Three decoration layers applied to 6+ cards per tab. The white stroke disappears in dark mode and may fail Increase Contrast. Shadow on a material surface adds unnecessary weight. This is a mild blur stack.

**Verdict:** Partially fighting the system. Remove the white stroke; reduce or remove the shadow.

---

#### 4. No source-linked sheet presentations
**Files:** `ChildWorkspaceTabView.swift`, `TimelineScreenView.swift`

No sheet in the app passes a source anchor. Event editing sheets, filter sheets, and the grouped timeline sheet all appear from the bottom with no visual connection to the control that triggered them. On iPad, several of these would naturally be popovers but are presented as unconstrained sheets.

Example:
```swift
// Filter button is in .topBarTrailing — but the sheet has no idea where it came from
.sheet(isPresented: $showingEventFilter) {
    EventFilterView(...)
}
```

**Verdict:** Missing significant easy wins.

---

#### 5. Error/sync banners use raw `.overlay` instead of safe-area-aware placement
**File:** `AppRootView.swift` lines 56–81

```swift
.overlay(alignment: .top) {
    if let errorMessage = model.errorMessage {
        ErrorBannerView(...)
            .padding(.top, 8)   // ← hardcoded, not safe-area-aware
    }
}
```

Can overlap the status bar or dynamic island on some devices. `.safeAreaBar(edge: .top)` is the correct API here.

---

#### 6. Double-styled segmented picker in Summary
**File:** `SummaryScreenView.swift`, `tabPicker`

```swift
Picker("Tab", selection: $selectedTab) { ... }
    .pickerStyle(.segmented)
    .padding(4)
    .background(                         // ← adds material behind a control that already has its own background
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
    )
```

The segmented picker has its own system appearance. The `.ultraThinMaterial` wrapper adds a second visual layer on top.

---

### LOW severity

#### 7. `InteractiveOnboardingView` swipe-back is a whole-view `DragGesture`
**File:** `InteractiveOnboardingView.swift` lines 142–150

Acceptable in a `fullScreenCover` context (no NavigationStack back gesture to conflict with), but the 60pt threshold is lower than the iOS system gesture threshold and the gesture isn't interruptible mid-motion. Low practical risk.

#### 8. `TabView(.page)` + explicit `DragGesture` in Timeline
**File:** `TimelineScreenView.swift` lines 44–72

The paged `TabView` for day navigation plus a `simultaneousGesture(DragGesture)` for edge-wrap logic is fragile. If a NavigationStack push is ever added above the Timeline, horizontal drags will conflict with the back gesture. Low current risk; higher future risk.

---

## Screen-by-Screen Audit

---

### Home Tab

**Purpose:** Current sleep status, recent event summaries, quick-log buttons, iCloud sync status.  
**Files:** `ChildHomeView.swift`, `CurrentSleepCardView.swift`, `CurrentStatusCardView.swift`

| Area | Rating |
|---|---|
| Navigation and back behavior | Using well |
| Tabs/top-level structure/search | Using well |
| Sheets/popovers/alerts/menus/dialogs | Using well |
| Bars/toolbars/chrome | Partially using |
| Custom Liquid Glass surfaces | Not using |
| Content flowing under chrome | Not using |
| Motion and continuity | Partially using |
| Accessibility and resilience | Using well |

**Findings:**
- `ScrollView` with `.background(Color(.systemGroupedBackground).ignoresSafeArea())` — background extends under the nav bar correctly; scroll-edge behavior works normally.
- Quick-log buttons use `.buttonStyle(.plain)` with solid color fills from `BabyEventStyle.buttonFillColor(for:)`. These are the strongest candidate for `glassEffect` in the app if a floating control style is wanted. Solid fills are fine as-is — not fighting the system.
- The sync status card uses `Color(.secondarySystemGroupedBackground)` + a separator stroke — functional and consistent.
- `NavigationLink` to `ChildProfileSyncView` from the sync card uses system back behavior — correct.
- No toolbar actions on Home — appropriate.

**Recommended fixes:**
1. No urgent structural changes. Home is the healthiest tab.
2. Consider `glassEffect` for quick-log buttons as a future Liquid Glass adoption point.

---

### Events Tab

**Purpose:** Full event history with type filtering, swipe-to-delete, and edit actions.  
**Files:** `EventHistoryView.swift`, `EventCardView.swift`, `EventFilterView.swift`

| Area | Rating |
|---|---|
| Navigation and back behavior | Using well |
| Tabs/top-level structure/search | Actively fighting the system |
| Sheets/popovers/alerts/menus/dialogs | Partially using |
| Bars/toolbars/chrome | Actively fighting the system |
| Custom Liquid Glass surfaces | Not using |
| Content flowing under chrome | Not using |
| Motion and continuity | Not using |
| Accessibility and resilience | Partially using |

**Findings:**
- **Filter pills bar** (`filterPillsBar`, lines 73–105): Custom horizontal scroll with manual background and divider. This is the second-most significant structural issue in the app after the Timeline header.
- **`List` with `.listStyle(.plain)`** + custom card views works correctly. Swipe actions and context menus use system APIs — good.
- **Filter sheet** opens as an unconstrained sheet with no source anchor — the system doesn't know it came from the toolbar button.
- **Custom section headers** (`sectionHeader(for:)`) use a rounded-rect background with a stroke overlay instead of system section header styling. Not fighting the system but adds custom decoration that won't adapt to future system styling changes.
- **`AnchoredDeletePromptView`**: This appears inline below a row when delete is pending. `.confirmationDialog` (used correctly in Timeline) would be more conventional and matches system patterns. Cannot fully evaluate `AnchoredDeletePromptView` without reading its implementation.

**Recommended fixes:**
1. Replace `filterPillsBar` with `.searchable` + filter tokens. (High impact)
2. Anchor the filter sheet to the toolbar filter button.
3. Evaluate replacing `AnchoredDeletePromptView` with `.confirmationDialog` to match Timeline behavior.

---

### Timeline Tab

**Purpose:** Hour-by-hour day grid of events with swipe navigation, plus a 7-day week strip view.  
**Files:** `TimelineScreenView.swift`, `TimelineDayGridView.swift`, `TimelineDayGridPageView.swift`, `TimelineWeekView.swift`

| Area | Rating |
|---|---|
| Navigation and back behavior | Partially using |
| Tabs/top-level structure/search | Not using |
| Sheets/popovers/alerts/menus/dialogs | Using well |
| Bars/toolbars/chrome | Actively fighting the system |
| Custom Liquid Glass surfaces | Not using |
| Content flowing under chrome | Actively fighting the system |
| Motion and continuity | Not using |
| Accessibility and resilience | Partially using |

**Findings:**
- **`pinnedDayNavigationHeader`** (lines 104–189): The most significant UI problem in the app. A custom bar built from scratch with `.regularMaterial` background and a hard `Divider()` separator that is always visible. Contains: week title, prev/next arrow buttons, day title, calendar picker button, "Today" button, and a weekday tab strip — three levels of custom chrome in one component.
- **`TabView(.page)`** + `simultaneousGesture(DragGesture)` for day navigation is fragile. The drag gesture handles edge cases (previous page from page 0, next page from last page) but adds gestural complexity outside the `TabView`'s normal behavior.
- **`.confirmationDialog` for delete** — correct and consistent with the guide's recommendation.
- **Day picker sheet** uses `.presentationDetents([.height(...)])` and `.presentationDragIndicator(.visible)` — good native sheet presentation.
- **Toolbar button for "Week View" / "Day View"** in `.topBarTrailing` — appropriate.

**Recommended fixes:**
1. **Replace `pinnedDayNavigationHeader` entirely.** Move day title to `.navigationTitle` or a `.principal` toolbar placement. Move prev/next buttons to `.topBarLeading` and `.topBarTrailing`. Move the weekday strip to a `safeAreaBar(edge: .top)` or eliminate it in favor of the navigation title. This is the single highest-impact change in the app. (High effort, high impact)
2. Consider replacing the paged `TabView` with a `ScrollView` using `scrollTargetBehavior` for more composable day navigation.

---

### Summary Tab

**Purpose:** Today's cumulative charts and event counts, plus trends charts across a selected time range.  
**Files:** `SummaryScreenView.swift`, `CumulativeLineChartView.swift`, `TrendsBarChartView.swift`, `AdvancedSummaryView.swift`

| Area | Rating |
|---|---|
| Navigation and back behavior | Using well |
| Tabs/top-level structure/search | Partially using |
| Sheets/popovers/alerts/menus/dialogs | Using well |
| Bars/toolbars/chrome | Partially using |
| Custom Liquid Glass surfaces | Partially using |
| Content flowing under chrome | Not using |
| Motion and continuity | Not using |
| Accessibility and resilience | Partially using |

**Findings:**
- **`tabPicker`**: Wraps a native `Picker(.segmented)` in `.ultraThinMaterial` with a rounded rect. The segmented picker has its own system appearance — the wrapper creates a double-styled control. Remove the wrapper.
- **`cardBackground`**: `.thinMaterial` + white stroke + shadow on every card. White stroke disappears in dark mode. Material is a good starting point but the extra decoration fights it. Simplify.
- **`.popover` for date picker** with `.presentationCompactAdaptation(.popover)` — correct.
- **`NavigationLink` to `AdvancedSummaryView`** — a zoom transition from the "More Information" card would meaningfully improve continuity.
- **`Picker(.menu)`** for chart filters — correct API for in-card filter selection.

**Recommended fixes:**
1. Remove `.ultraThinMaterial` background wrapper from `tabPicker`. (Low effort)
2. Simplify `cardBackground` — remove the white stroke overlay. (Low effort)
3. Add `.navigationTransition(.zoom)` + `matchedTransitionSource` to the AdvancedSummaryView link. (Medium effort)

---

### Profile Tab

**Purpose:** Child info, photo, caregiver management, data import/export, CloudKit sharing, archive/delete.  
**Files:** `ChildProfileView.swift`, `AppSettingsView.swift`, and related detail views

| Area | Rating |
|---|---|
| Navigation and back behavior | Using well |
| Tabs/top-level structure/search | Using well |
| Sheets/popovers/alerts/menus/dialogs | Using well |
| Bars/toolbars/chrome | Using well |
| Custom Liquid Glass surfaces | Not using |
| Content flowing under chrome | Not using |
| Motion and continuity | Not using |
| Accessibility and resilience | Using well |

**Findings:**
- `AppSettingsView` uses `List(.insetGrouped)` with `NavigationLink` — correct and idiomatic.
- `NavigationLink` chains to sub-screens with system back behavior — correct.
- No custom bars, no custom overlays — the Profile tab is the most platform-native section of the app.
- `fullScreenCover` for "Preview New Onboarding" from `AppSettingsView` — acceptable debug/help feature.

**Recommended fixes:**
1. No urgent changes. This tab is the model for the rest of the app.

---

### Onboarding Flow

**Purpose:** Introduce the app, collect caregiver name and first child, log first event.  
**Files:** `InteractiveOnboardingView.swift`, `IdentityOnboardingView.swift`, and 15+ supporting files

| Area | Rating |
|---|---|
| Navigation and back behavior | Partially using |
| Tabs/top-level structure | N/A |
| Sheets/popovers/alerts/menus/dialogs | Using well |
| Bars/toolbars/chrome | Not using |
| Custom Liquid Glass surfaces | Not using |
| Content flowing under chrome | N/A |
| Motion and continuity | Partially using |
| Accessibility and resilience | Using well |

**Findings:**
- **`fullScreenCover` for the onboarding** — appropriate; persisting across route changes during user/child creation is the right call.
- **Custom top bar** (lines 174–191): A manually built `HStack` with "Nest" brand label and "Skip" button. Reasonable for a `fullScreenCover` flow where no system nav chrome is wanted.
- **`LinearGradient` background** — appropriate for onboarding; restrained tint with `.accentColor.opacity(0.08)`.
- **`DragGesture` swipe-back** — acceptable in this `fullScreenCover` context; `accessibilityReduceMotion` correctly disables transitions.
- **`.alert(item:)` for notification permission** — correct system alert usage.
- **Custom page indicator** (capsule dots) — `TabView(.page)` with `indexDisplayMode: .always` would provide this for free, but the custom dots are acceptable in this context.

**Recommended fixes:**
1. No urgent structural changes. Onboarding is intentionally custom and handles accessibility correctly.

---

## Prioritized Action Plan

| Priority | Recommendation | Why it matters | Effort | Risk | Files likely to change |
|---|---|---|---|---|---|
| 1 | Replace `pinnedDayNavigationHeader` with toolbar placements and `.safeAreaBar` | Eliminates the app's biggest custom-bar anti-pattern; unblocks content-under-chrome and future glass adoption | L | Medium | `TimelineScreenView.swift` |
| 2 | Replace `filterPillsBar` with `.searchable` + filter tokens | Removes the second custom-bar anti-pattern; puts search where users expect it | M | Medium | `EventHistoryView.swift`, `EventHistoryViewModel.swift` |
| 3 | Replace `.overlay(alignment: .top)` error/sync banners with `.safeAreaBar(edge: .top)` | Correct placement on all device families including Dynamic Island devices | S | Low | `AppRootView.swift` |
| 4 | Remove custom `.ultraThinMaterial` background from Summary tab picker | Segmented picker has its own appearance; the wrapper creates a double-styled control | S | Low | `SummaryScreenView.swift` |
| 5 | Simplify `cardBackground` — remove white stroke, reduce shadow | Fixes dark mode failure and Increase Contrast resilience on every Summary card | S | Low | `SummaryScreenView.swift` |
| 6 | Add `matchedTransitionSource` + `.navigationTransition(.zoom)` to AdvancedSummaryView link | Source continuity for the most important push navigation in the app | M | Low | `SummaryScreenView.swift`, `AdvancedSummaryView.swift` |
| 7 | Add source anchoring to event-log sheets and filter sheet | Makes presentations feel connected to the control that triggered them | M | Low | `ChildWorkspaceTabView.swift` |
| 8 | Align Events delete confirm to `.confirmationDialog` (matching Timeline pattern) | Consistent delete UX across tabs; removes inline `AnchoredDeletePromptView` pattern | S | Low | `EventHistoryView.swift` |
| 9 | Introduce `glassEffect` for quick-log buttons on Home screen | These are the best candidate for custom glass — floating action controls with distinct purposes | M | Low | `ChildHomeView.swift` |
| 10 | Add `ToolbarSpacer` between toolbar items as the toolbar grows | Prepares for toolbar growth with intentional visual grouping | S | Low | `ChildWorkspaceTabView.swift` |

---

## Suggested Code Changes

### 1. Fix error/sync banner placement in `AppRootView`

**Current** (`AppRootView.swift` lines 56–81):
```swift
.overlay(alignment: .top) {
    ZStack(alignment: .topTrailing) {
        if let errorMessage = model.errorMessage {
            ErrorBannerView(...)
                .padding(.horizontal, 16)
                .padding(.top, 8)   // ← hardcoded, not safe-area-aware
        }
        if let syncBannerState = model.syncBannerState {
            SyncIndicatorView(state: syncBannerState)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
    }
}
```

**Suggested:**
```swift
.safeAreaBar(edge: .top) {
    if let errorMessage = model.errorMessage {
        ErrorBannerView(message: errorMessage, dismissAction: model.dismissError)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}
.overlay(alignment: .topTrailing) {
    if let syncBannerState = model.syncBannerState {
        SyncIndicatorView(state: syncBannerState)
            .padding(.top, 8)
            .padding(.trailing, 16)
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                )
            )
    }
}
.animation(.spring(response: 0.38, dampingFraction: 0.82), value: model.syncBannerState != nil)
```

`safeAreaBar` places the error banner correctly relative to the status bar and dynamic island. The compact sync indicator can remain in `.overlay` since it's a small trailing icon that doesn't need to push content down.

---

### 2. Simplify `cardBackground` in `SummaryScreenView`

**Current** (`SummaryScreenView.swift` lines 864–872):
```swift
private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)   // ← remove: invisible in dark mode
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 8) // ← remove or reduce significantly
}
```

**Suggested:**
```swift
private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
}
```

Or keep `.thinMaterial` if the translucency is intentional — but drop the white stroke and shadow entirely. The material provides sufficient differentiation from the grouped background.

---

### 3. Remove custom background from Summary tab picker

**Current** (`SummaryScreenView.swift`):
```swift
private var tabPicker: some View {
    Picker("Tab", selection: $selectedTab) {
        ForEach(SummaryTab.allCases, id: \.self) { tab in
            Text(tab.rawValue).tag(tab)
        }
    }
    .pickerStyle(.segmented)
    .padding(4)
    .background(                        // ← remove entirely
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
    )
}
```

**Suggested:**
```swift
private var tabPicker: some View {
    Picker("Tab", selection: $selectedTab) {
        ForEach(SummaryTab.allCases, id: \.self) { tab in
            Text(tab.rawValue).tag(tab)
        }
    }
    .pickerStyle(.segmented)
}
```

---

### 4. Add zoom transition to AdvancedSummaryView NavigationLink

**Current** (`SummaryScreenView.swift`):
```swift
private var advancedSummaryLink: some View {
    NavigationLink {
        AdvancedSummaryView(...)
    } label: {
        HStack { ... }
            .padding(16)
            .background(cardBackground)
    }
    .buttonStyle(.plain)
}
```

**Suggested:**
```swift
@Namespace private var advancedSummaryNamespace

private var advancedSummaryLink: some View {
    NavigationLink {
        AdvancedSummaryView(...)
            .navigationTransition(.zoom(sourceID: "advancedSummary", in: advancedSummaryNamespace))
    } label: {
        HStack { ... }
            .padding(16)
            .background(cardBackground)
    }
    .buttonStyle(.plain)
    .matchedTransitionSource(id: "advancedSummary", in: advancedSummaryNamespace)
}
```

---

### 5. Quick-log buttons with `glassEffect` (Home screen)

**Current** (`ChildHomeView.swift` lines 204–224):
```swift
private func quickLogButton(...) -> some View {
    Button(action: action) {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, 14)
            .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: kind))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BabyEventStyle.buttonFillColor(for: kind))   // ← solid fill
            )
    }
    .buttonStyle(.plain)
}
```

**Suggested** (if adopting Liquid Glass for these controls):
```swift
private func quickLogButton(...) -> some View {
    Button(action: action) {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, 14)
            .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: kind))
    }
    .buttonStyle(.plain)
    .glassEffect(
        .regular.tint(BabyEventStyle.buttonFillColor(for: kind).opacity(0.3)),
        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
    )
}
```

Wrap all four buttons in a `GlassEffectContainer` for coordinated rendering:
```swift
GlassEffectContainer {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            quickLogButton(title: "Breast Feed", ...)
            quickLogButton(title: "Bottle Feed", ...)
        }
        HStack(spacing: 12) {
            quickLogButton(title: sleepQuickLogTitle, ...)
            quickLogButton(title: "Nappy", ...)
        }
    }
}
```

Note: Only adopt this after verifying legibility over the grouped background across light, dark, and Increase Contrast modes. The current solid fills are readable and not wrong — this is an optional enhancement, not a fix.

---

## Key Principle

Do not add `glassEffect` until the custom bars are removed. Adding glass on top of the current custom chrome in Timeline and Events would create three competing visual layers rather than a coherent system. The correct adoption order:

1. **Fix the bars** — Timeline header, Events filter bar, error banner placement
2. **Remove over-styling** — Summary card white stroke, picker double-background
3. **Add source continuity** — sheet anchors, zoom transition for AdvancedSummary
4. **Add glass sparingly** — quick-log buttons on Home are the strongest candidate
