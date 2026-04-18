# Liquid Glass App Audit Findings

Generated: 2026-04-18 20:11 IST

Rubric used: `/Users/brianmurphy/Documents/Development/iOS/Baby Tracker/docs/liquid-glass-app-audit-guide.md`

## Executive summary

- The app is strongly SwiftUI-first and already uses the main system containers well: `NavigationStack`, `TabView`, `List`, `sheet`, `popover`, `confirmationDialog`, `Menu`, `contextMenu`, `swipeActions`, `refreshable`, and `.searchable`.
- The root flow is cleanly routed through `AppRootView`, which keeps top-level navigation native and uses a `NavigationStack` instead of a custom router UI.
- The best-native-feeling areas are the standard settings/profile surfaces, the logs screen, the help/FAQ screen, and the CloudKit share sheet, because they lean on system components rather than inventing new ones.
- The app is not taking advantage of the newer Liquid Glass surface model very much. I found no usage of `safeAreaBar`, `ToolbarSpacer`, `glassEffect`, `GlassEffectContainer`, `glassEffectID`, `backgroundExtensionEffect`, `matchedTransitionSource`, or `navigationTransition`.
- A lot of the app still uses pre-Liquid-Glass card styling: rounded rectangles, explicit separator strokes, opaque grouped backgrounds, and repeated drop shadows.
- The most obvious place where the app is fighting the system is the timeline screen, which uses a custom pinned header plus a custom drag gesture around a page `TabView` instead of letting the system chrome and navigation behavior do more of the work.
- Root-level banners in `AppRootView` are also custom floating chrome with thin/ultra-thin material, shadows, and manual top placement. They are functional, but they compete with the system instead of feeling like a native bar or safe-area surface.
- Accessibility is partially considered: `InteractiveOnboardingView` respects Reduce Motion, and many texts use standard semantic styles. But there is no code-level handling for Reduce Transparency or Increase Contrast, and several custom surfaces rely on translucency and shadow for hierarchy.
- Static inspection suggests there are no UIKit appearance hacks in the app target. That is good. The main issue is not legacy UIKit customization; it is custom SwiftUI chrome that duplicates or works around the system.
- Overall verdict: the app is already using the platform structure, but it is leaving a lot of native feel on the table by over-styling cards/chrome and by building a few custom navigation-like surfaces that the system could handle better.

## What the app is already doing well

### Root navigation and top-level flow

- `Baby Tracker/App/AppRootView.swift` uses a top-level `NavigationStack` and switches between routes with standard SwiftUI views instead of a custom router shell.
- `AppRootView` hides the navigation bar only on the loading/onboarding/no-children states, which is appropriate for full-bleed onboarding and transitional states.
- `AppRootView` uses `fullScreenCover` for `InteractiveOnboardingView`, which is the right native presentation for a blocking onboarding flow.
- `AppRootView` also uses `safeAreaInset(edge: .bottom)` for transient banners rather than pinning them with absolute coordinates.
- `AppRootView` uses system `onOpenURL` handling to drive a Live Activity deep link into the sleep sheet flow.

### Standard top-level structure

- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildWorkspaceTabView.swift` uses a standard `TabView` with `tabItem` labels for the main sections: Home, Events, Timeline, Summary, and Profile.
- The child workspace uses a single navigation title for the selected child, which is a reasonable use of the system bar instead of recreating a custom app shell.
- `ChildWorkspaceTabView` uses `ToolbarItem` placements for the event filter and timeline display toggle instead of making those controls fully custom.

### Native presentations and interactions

- `TimelineScreenView` uses a real `sheet` for the day picker and a system `confirmationDialog` for event deletion.
- `SummaryScreenView` uses a real `popover` for date selection and a system `Picker` for section switching and chart filters.
- `LoggingView` uses `.searchable(text:prompt:)`, `Menu`, and `sheet(item:)` for exporting logs, which is exactly the kind of built-in behavior the guide recommends.
- `EventHistoryView` uses `refreshable`, `swipeActions`, `contextMenu`, and a `List` with sections, which gives the screen a strong native interaction model.
- `HelpFAQView` uses `DisclosureGroup` inside an inset grouped `List`, which is a good fit for expandable support content.
- `ChildProfileView` and `AppSettingsView` use ordinary `List`, `Section`, `NavigationLink`, `Toggle`, `Picker`, and `Button` primitives for settings-style navigation.
- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/CloudKitShareSheetView.swift` wraps `UICloudSharingController`, which keeps CloudKit sharing on a native controller instead of a custom modal.
- `LoggingView` wraps `UIActivityViewController` for sharing/export, which is correct and avoids a fake share sheet.

### Accessibility-aware behavior already present

- `InteractiveOnboardingView` checks `accessibilityReduceMotion` and simplifies its transitions when motion reduction is enabled.
- `CurrentSleepCardView` uses monospaced digits and a `TimelineView` for the running timer, which is a solid choice for live-updating status text.
- Many labels use semantic font styles (`headline`, `subheadline`, `caption`) rather than fixed typography everywhere.
- Several interactive rows and cards include accessibility identifiers, which is useful for automation and regression coverage.

## Easy wins being missed

### Root chrome and banners

- `AppRootView` has three floating surfaces stacked above the root content: `ErrorBannerView`, `SyncIndicatorView`, and the bottom `TransientMessageBannerView` / `UndoBannerView` stack.
- Those banners are useful, but they are styled as separate custom glass elements with shadows instead of being integrated into the native bar/safe-area system.
- This is low risk to improve because the logic already exists; only the presentation container needs to change.

### Timeline header and day navigation

- `TimelineScreenView` builds its own pinned header with a regular material background, a divider, custom buttons, and a row of weekday tiles.
- This could be moved closer to the system bar model or turned into a safer `safeAreaBar`/toolbar-based layout.
- The screen already has a `ToolbarItem` in the parent `ChildWorkspaceTabView` for the day-mode toggle, so some of the chrome is already split correctly. The day navigation itself still needs that treatment.

### Summary surface styling

- `SummaryScreenView` uses a repeated `cardBackground` consisting of `thinMaterial`, a white stroke, and a drop shadow for nearly every section.
- That is visually heavy compared with the native grouped/list styles the rest of the app already uses.
- This is an easy place to remove styling before adding any new Liquid Glass styling.

### Custom card shells everywhere

- `ChildHomeView`, `CurrentStatusCardView`, `CurrentSleepCardView`, `ChildPickerView`, `NoChildrenView`, `EventHistoryView`, `AnchoredDeletePromptView`, and many onboarding demo views all repeat the same pattern: rounded rectangle, grouped background, separator stroke, and shadow.
- The result is consistent, but it is a pre-Liquid-Glass visual language that makes the app feel more themed than native.
- These can be simplified incrementally, one screen at a time.

### Missing source-linked continuity

- I found no `matchedTransitionSource`, `navigationTransition`, `glassEffectID`, or comparable source-anchored transition work.
- The app already has natural places for it, especially `SummaryScreenView` -> `AdvancedSummaryView`, event cards -> editor sheets, and the onboarding demo steps.
- This is not a bug. It is a missed system-feel opportunity.

### Missing accessibility branches

- I found no code-level handling for `accessibilityDifferentiateWithoutColor`, `accessibilityIncreaseContrast`, or `accessibilityReduceTransparency`.
- Because many surfaces rely on material, translucent backgrounds, and subtle shadows, those settings could materially affect legibility.
- Static inspection cannot prove a problem, but it does show the app is not adapting those settings explicitly.

## Places fighting the system

### High severity

#### Timeline screen is building custom chrome and custom paging behavior

- `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/TimelineScreenView.swift` uses a custom pinned header (`pinnedDayNavigationHeader`) that duplicates some of what a navigation bar or safe-area bar would normally do.
- The screen also adds a custom `DragGesture` on top of a `.page` `TabView` to interpret day navigation at the edges.
- That is the clearest place where the app is fighting native behavior because it competes with the standard paging gesture model and can create edge-swipe ambiguity near navigational contexts.

#### Root overlays compete with system bars

- `Baby Tracker/App/AppRootView.swift` places error, sync, transient, and undo surfaces directly on top of the whole app.
- They are styled as glassy floating chips with shadows and manual padding.
- The result is useful but visually fragmented: instead of one coherent native surface system, the app has multiple ad hoc overlays with slightly different shapes and elevation.

### Medium severity

#### Summary uses heavy card styling instead of letting the system carry hierarchy

- `SummaryScreenView` leans hard on `cardBackground`, `thinMaterial`, white strokes, and shadows across most sections.
- The screen already sits inside a `ScrollView` with standard `Picker` controls. The extra chrome is not needed for comprehension and makes the screen feel more decorative than native.

#### Child picker and no-children screens use manually styled cards where standard rows would work

- `ChildPickerView` and `NoChildrenView` both use rounded cards, grouped fills, and shadows for what are essentially large navigation choices.
- Those screens could feel simpler and more native if the primary actions were presented with ordinary list-like structure, or with fewer visual layers.

#### Event history filter row and delete prompt are custom shells

- `EventHistoryView` uses a custom horizontally scrolling filter-pill bar and a custom `AnchoredDeletePromptView` instead of leaning more on the list, menu, or confirmation dialog system.
- The delete prompt is especially custom: it sits inline under the row, but it is drawn as a mini card with its own shadow and border.

#### Interactive onboarding uses a lot of decorative layering

- `InteractiveOnboardingView` uses a custom full-screen gradient background, horizontal drag gesture, and multiple demo screens with blur/shadow/material stacks.
- This is not a structural problem, but it is a lot of extra motion and decoration on top of a flow that should mostly be teaching and setup.

### Low severity

#### Logging and settings screens are mostly fine, but still somewhat card-heavy

- `LoggingView`, `ChildProfileView`, `AppSettingsView`, and `HelpFAQView` are structurally native, but the app’s custom row styling still leaks into those screens.
- These are not the first files to change, but they would benefit from less manual styling over time.

## Screen-by-screen audit

### 1) Root app shell and route router

- Purpose: choose the current top-level flow, present onboarding, and surface global banners.
- Relevant files/types: `Baby Tracker/App/AppRootView.swift`, `BabyTrackerApp.swift`, `CloudKitShareAppDelegate.swift`, `CloudKitShareSceneDelegate.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Partially using.
- Sheets/popovers/alerts/menus/dialogs: Using well.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Partially using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - The root `NavigationStack` is correct.
  - The onboarding cover is correct.
  - The global banners are the weakest part: useful, but styled as multiple independent floating chips instead of one system-like bar surface.
  - I did not find UIKit bar appearance overrides.
- Recommended fixes:
  - Move persistent top/bottom status surfaces closer to safe-area bar semantics.
  - Consolidate banner styling so all root overlays feel like one system family.

### 2) Child picker / no-children entry flow

- Purpose: let the user choose or create a child profile, or explain that no children exist yet.
- Relevant files/types: `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/ChildPickerView.swift`, `NoChildrenView.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Not using.
- Sheets/popovers/alerts/menus/dialogs: Partially using.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Not using.
- Content flowing under chrome: Not using.
- Motion and continuity: Not using.
- Accessibility and resilience: Partially using.
- Findings:
  - The navigation containers are standard.
  - The screen design is more card-based than native list-based.
  - The cards are readable, but the shadowed rounded rectangles feel heavier than needed for a simple picker.
- Recommended fixes:
  - Reduce card decoration on the primary actions.
  - Consider whether the “choose profile” screen can lean on standard row affordances more directly.

### 3) Child workspace shell

- Purpose: host the main five-tab experience for a selected child.
- Relevant files/types: `ChildWorkspaceTabView.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Using well.
- Sheets/popovers/alerts/menus/dialogs: Using well.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Partially using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - This is the best example of standard iOS structure in the app.
  - The tab bar is native; the parent navigation title is native; the toolbar items are native.
  - The issue is not the container; it is the amount of custom screen chrome inside the tabs.
- Recommended fixes:
  - Keep the tab shell.
  - Remove custom top chrome where a toolbar or safe-area bar would be better.

### 4) Home tab

- Purpose: show current sleep, current status, quick log actions, and sync entry.
- Relevant files/types: `ChildHomeView.swift`, `CurrentStatusCardView.swift`, `CurrentSleepCardView.swift`, `SyncIndicatorView.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Partially using.
- Sheets/popovers/alerts/menus/dialogs: Not using.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Not using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - The screen is logically organized and the quick actions are easy to find.
  - The sync card and current status card are both custom rounded surfaces with borders and fills.
  - The quick-log buttons are large and clear, but still self-styled rather than system-generic.
  - `SyncIndicatorView` is a small custom glass chip; it is functional, but it adds another independent floating surface to the app root.
- Recommended fixes:
  - Simplify the card shells.
  - Consider whether the sync entry belongs in a toolbar or bar-adjacent surface instead of a bespoke card.

### 5) Events tab

- Purpose: browse events chronologically, filter them, and manage edits/deletes.
- Relevant files/types: `EventHistoryView.swift`, `AnchoredDeletePromptView.swift`, `EventCardView.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Partially using.
- Sheets/popovers/alerts/menus/dialogs: Using well.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Not using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - `List`, `swipeActions`, `contextMenu`, and `refreshable` are all correct.
  - The filter pill bar is entirely custom and visually separate from the list.
  - The inline anchored delete prompt is helpful, but it is also a custom card layered into a list, which makes the screen feel less native than a confirmation dialog would.
- Recommended fixes:
  - Keep `swipeActions`.
  - Revisit whether the delete confirmation should remain inline or move to a standard confirmation surface.
  - Reduce the custom chrome around the filter pills if possible.

### 6) Timeline tab

- Purpose: show daily or weekly event layout and allow day navigation.
- Relevant files/types: `TimelineScreenView.swift`, `TimelineDayGridView.swift`, `TimelineDayGridPageView.swift`, `TimelineWeekView.swift`, `TimelineDayGridGroupedEventsSheetView.swift`.
- Navigation and back behavior: Partially using.
- Tabs/top-level structure/search: Not using.
- Sheets/popovers/alerts/menus/dialogs: Using well.
- Bars/toolbars/chrome: Actively fighting the system.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Partially using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - The page-based day `TabView` is fine, but the extra drag gesture is the problem.
  - The pinned header is effectively a custom bar. It uses `regularMaterial`, a divider, and a bunch of buttons, which makes it feel like a home-grown navigation chrome.
  - The day picker sheet is native and good.
  - The per-day grid uses custom backgrounds and separators but is not the main problem. The header is.
- Recommended fixes:
  - Remove the custom edge-swipe logic unless there is a very strong product reason to keep it.
  - Move day navigation and mode switching into the system toolbar/safe-area bar pattern.
  - Let the page `TabView` manage paging without a second gesture layer competing with it.

### 7) Summary tab

- Purpose: show today/trends summaries, charts, and a link to detailed analytics.
- Relevant files/types: `SummaryScreenView.swift`, `AdvancedSummaryView.swift`, `TrendsBarChartView.swift`, `TrendsNappyChartView.swift`, `CumulativeLineChartView.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Partially using.
- Sheets/popovers/alerts/menus/dialogs: Using well.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Not using.
- Content flowing under chrome: Not using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - The screen uses standard `Picker`, `popover`, and `NavigationLink`, which is good.
  - The repeated `cardBackground` pattern is heavy: material, white stroke, and shadow on nearly every card.
  - The date selector is source-linked only in the ordinary sense of a popover attached to a button. There is no deeper source transition work.
  - This is one of the best candidates for simplifying rather than adding more custom styling.
- Recommended fixes:
  - Remove extra shadow/stroke layers first.
  - Keep the charts, but let the surrounding chrome become quieter.
  - Consider source-linked transitions for the link into `AdvancedSummaryView` if you want a better continuity story.

### 8) Profile, settings, help, and logs

- Purpose: manage the child profile, app settings, exports, help, and diagnostics.
- Relevant files/types: `ChildProfileView.swift`, `AppSettingsView.swift`, `HelpFAQView.swift`, `LoggingView.swift`, `ChildProfileDetailsView.swift`, `ChildProfileManageView.swift`.
- Navigation and back behavior: Using well.
- Tabs/top-level structure/search: Partially using.
- Sheets/popovers/alerts/menus/dialogs: Using well.
- Bars/toolbars/chrome: Using well.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Not using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - These screens are structurally the most native in the app.
  - `HelpFAQView` is especially good because it uses a plain list with disclosure groups.
  - `LoggingView` is also good because search and menus are native.
  - The main issue is visual consistency: the app’s custom card language still leaks into rows and sub-surfaces.
- Recommended fixes:
  - Keep the system list and menu patterns.
  - Simplify the remaining custom row/cell decoration.

### 9) Interactive onboarding

- Purpose: teach the product and collect initial profile data.
- Relevant files/types: `InteractiveOnboardingView.swift`, `OnboardingIntroStepView.swift`, `OnboardingAppPreviewStepView.swift`, `OnboardingQuickLogDemoView.swift`, `OnboardingTimelineDemoView.swift`, `OnboardingChartsDemoView.swift`, `OnboardingLiveActivityDemoView.swift`, `OnboardingNotificationsDemoView.swift`, `IdentityOnboardingNameStepView.swift`, `OnboardingAddBabyStepView.swift`, `OnboardingFirstEventStepView.swift`.
- Navigation and back behavior: Partially using.
- Tabs/top-level structure/search: Not using.
- Sheets/popovers/alerts/menus/dialogs: Partially using.
- Bars/toolbars/chrome: Partially using.
- Custom Liquid Glass surfaces: Partially using.
- Content flowing under chrome: Not using.
- Motion and continuity: Partially using.
- Accessibility and resilience: Partially using.
- Findings:
  - The onboarding flow already uses `Reduce Motion` awareness, which is good.
  - The main drag gesture is custom and global across the screen.
  - The demo content is visually heavy, with blur, shadow, and material layering that is more decorative than structural.
- Recommended fixes:
  - Keep the teaching flow, but simplify the styling and motion where possible.
  - Make sure the flow still feels legible at large Dynamic Type sizes and with transparency reduction enabled.

## Prioritized action plan

| Priority | Recommendation | Why it matters | Estimated effort | Risk | Files likely to change |
| --- | --- | --- | --- | --- | --- |
| 1 | Remove or redesign the custom drag gesture and pinned chrome in `TimelineScreenView` | This is the clearest place where custom behavior fights native navigation/paging expectations | M | Medium | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/TimelineScreenView.swift`, possibly `TimelineWeekView.swift` |
| 2 | Move root banners to a more native bar/safe-area model | The app currently has three separate floating overlay systems at the root | M | Medium | `Baby Tracker/App/AppRootView.swift`, `ErrorBannerView.swift`, `SyncIndicatorView.swift`, `TransientMessageBannerView.swift`, `UndoBannerView.swift` |
| 3 | Strip the extra shadow/stroke/material stack from `SummaryScreenView` cards | This is repeated everywhere and makes the app feel older than it is | M | Low | `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/SummaryScreenView.swift` |
| 4 | Simplify the card styling in `ChildHomeView`, `CurrentStatusCardView`, `CurrentSleepCardView`, `ChildPickerView`, and `NoChildrenView` | These screens are structurally native but visually over-decorated | M | Low | the listed view files |
| 5 | Reevaluate the inline anchored delete prompt in `EventHistoryView` | A standard confirmation surface may feel more native and reduce custom chrome | S | Low | `EventHistoryView.swift`, `AnchoredDeletePromptView.swift` |
| 6 | Add source-linked continuity where the app already has obvious source/destination pairs | This would improve perceived polish without changing product behavior | M | Low | `SummaryScreenView.swift`, `AdvancedSummaryView.swift`, `EventHistoryView.swift`, editor sheet views |
| 7 | Add explicit accessibility branches for Reduce Transparency / Increase Contrast | The app uses material and translucent styling in multiple places, so these settings matter | M | Low | root overlays, `SummaryScreenView.swift`, `TimelineScreenView.swift`, onboarding views, banner/card views |
| 8 | Revisit root and timeline chrome placement with `ToolbarSpacer` / `safeAreaBar` | This is the cleanest way to align custom chrome with Liquid Glass rather than fighting it | M | Medium | `AppRootView.swift`, `TimelineScreenView.swift`, possibly `ChildWorkspaceTabView.swift` |

## Suggested code changes

### 1) Replace root overlay stacks with native-safe-area style chrome

Current pattern in `AppRootView`:

```swift
.overlay(alignment: .top) {
    ZStack(alignment: .topTrailing) {
        if let errorMessage = model.errorMessage { ... }
        if let syncBannerState = model.syncBannerState { ... }
    }
}
.safeAreaInset(edge: .bottom) {
    VStack(spacing: 8) {
        if let transientMessage = model.transientMessage { ... }
        if let undoDeleteMessage = model.undoDeleteMessage { ... }
    }
}
```

More native direction:

```swift
.safeAreaBar(edge: .top) {
    HStack(spacing: 8) {
        if let errorMessage = model.errorMessage {
            ErrorBannerView(...)
        }

        Spacer()

        if let syncBannerState = model.syncBannerState {
            SyncIndicatorView(state: syncBannerState)
        }
    }
}
.safeAreaBar(edge: .bottom) {
    VStack(spacing: 8) {
        if let transientMessage = model.transientMessage {
            TransientMessageBannerView(message: transientMessage)
        }

        if let undoDeleteMessage = model.undoDeleteMessage {
            UndoBannerView(message: undoDeleteMessage, undoAction: model.undoLastDeletedEvent)
        }
    }
}
```

If `safeAreaBar` is not available on the deployment target/SDK combination you are using, the fallback should still be a single, coherent safe-area-aware container rather than multiple ad hoc overlays.

### 2) Simplify the timeline header and remove the custom edge swipe

Current pattern in `TimelineScreenView`:

```swift
TabView(selection: timelinePageBinding) { ... }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .simultaneousGesture(DragGesture(minimumDistance: 20) { ... })
```

Better direction:

```swift
// Let the page TabView handle paging.
TabView(selection: timelinePageBinding) { ... }
    .tabViewStyle(.page(indexDisplayMode: .never))

// Keep day navigation in the toolbar or a safe-area bar.
ToolbarItemGroup(placement: .topBarTrailing) {
    Button { viewModel.showPreviousDay() } label: { Image(systemName: "chevron.left") }
    Button { showingDayPicker = true } label: { Image(systemName: "calendar") }
    Button("Today") { viewModel.jumpToToday() }
    Button { viewModel.showNextDay() } label: { Image(systemName: "chevron.right") }
}
```

This removes a gesture layer that can compete with the system’s own back/paging gestures.

### 3) Remove extra card chrome from summary and home surfaces

Current summary card background:

```swift
RoundedRectangle(cornerRadius: 18, style: .continuous)
    .fill(.thinMaterial)
    .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.28), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 14, y: 8)
```

Cleaner direction:

```swift
RoundedRectangle(cornerRadius: 18, style: .continuous)
    .fill(Color(.secondarySystemGroupedBackground))
```

or, if you want to keep some material:

```swift
RoundedRectangle(cornerRadius: 18, style: .continuous)
    .fill(.regularMaterial)
```

The same simplification applies to `CurrentStatusCardView`, `CurrentSleepCardView`, `ChildPickerView`, `NoChildrenView`, and `AnchoredDeletePromptView`.

### 4) Add continuity where it helps

Example for `SummaryScreenView` -> `AdvancedSummaryView`:

```swift
@Namespace private var summaryNamespace

NavigationLink {
    AdvancedSummaryView(viewModel: viewModel, initialSelection: ...)
        .navigationTransition(.zoom(sourceID: "advanced-summary", in: summaryNamespace))
} label: {
    advancedSummaryLinkLabel
        .matchedTransitionSource(id: "advanced-summary", in: summaryNamespace)
}
```

That gives the detail screen a visible source instead of making it feel like an unrelated push.

### 5) Make accessibility settings first-class for translucent surfaces

Pattern to apply around material-heavy views:

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityIncreaseContrast) private var increaseContrast

private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(reduceTransparency ? Color(.secondarySystemGroupedBackground) : .thinMaterial)
        .overlay {
            if increaseContrast {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.primary.opacity(0.35), lineWidth: 1)
            }
        }
}
```

This matters most in `SummaryScreenView`, `TimelineScreenView`, `AppRootView`, the onboarding demo views, and the custom banner views.

## Notes on uncertainty

- I could not verify runtime legibility, motion behavior, or actual Liquid Glass rendering from static source alone.
- I did not find UIKit appearance overrides, but that is based on code inspection only.
- I did not find any usages of `safeAreaBar`, `ToolbarSpacer`, `glassEffect`, `GlassEffectContainer`, `glassEffectID`, `backgroundExtensionEffect`, `matchedTransitionSource`, or `navigationTransition`; that is a static-search result, not a runtime assertion.
- The app may still look better or worse on-device depending on the deployment target and current SDK. The recommendations above are based on code structure, not screenshots.
