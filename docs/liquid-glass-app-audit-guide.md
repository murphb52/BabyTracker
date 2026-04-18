# Liquid Glass App Audit + Styling Guide

## What this document is for

Use this guide to audit an existing iOS app for:

- native iOS UX you get almost for free
- Liquid Glass adoption opportunities
- places where custom styling is fighting the system
- practical next steps for SwiftUI or UIKit

This is designed as a **screen-by-screen checklist**. Walk through each major screen in your app and mark each item as:

- **Using well**
- **Partially using**
- **Not using**
- **Actively fighting the system**

---

## The core rule

The slickest iOS apps usually do **less custom drawing and less custom behavior**, not more.

Apple's current guidance is to start with standard navigation, bars, tabs, sheets, menus, popovers, search, and controls, because Liquid Glass and the new system behaviors are already built into those components. Recompiling with the new SDK and removing old appearance hacks can get you a surprising amount of the new feel with very little code. [1][2][3]

---

## The fast mental model

There are three categories of "free wins":

### 1) Structure
Use the system containers first:

- `NavigationStack` / `UINavigationController`
- `TabView` / `UITabBarController`
- split views and inspectors where appropriate
- system sheets, popovers, alerts, dialogs, menus
- built-in search placement

These automatically pick up the new design behavior more than custom containers do. [1][2][3]

### 2) Provenance
Transient UI should feel like it came from somewhere:

- a sheet should feel launched from the thing that opened it
- a popover should be anchored to its source
- a zoom transition should connect source and destination
- menus and dialogs should emerge from the control that triggered them

This source continuity is one of the biggest differences between "technically native" and "feels native". [2][4]

### 3) Material
Use Liquid Glass as a **surface system**, not as decoration:

- bars and controls float above content
- the material adapts to what is behind it
- the system gives hierarchy through grouping, layering, and motion
- custom glass should be rare and deliberate

Apple explicitly recommends using standard components first, then adding custom glass only where it earns its keep. [1][2][5]

---

# Part 1 - Audit checklist

## A. Navigation and back behavior

### What good looks like

- Your app uses system navigation containers rather than a home-grown router UI.
- Standard back behavior works everywhere it should.
- Swipe-to-go-back feels reliable and not fragile.
- You only use custom navigation transitions when continuity is genuinely helpful.

### Check each screen

- [ ] Uses `NavigationStack` / `UINavigationController` instead of a custom push/pop illusion.
- [ ] Preserves the standard back button and back gesture.
- [ ] No horizontal drag gesture, card swipe, carousel, or pager is accidentally blocking back navigation.
- [ ] If using zoom transitions, the source and destination have clear visual continuity.
- [ ] The interaction still feels correct when interrupted mid-gesture.

### What to flag

- **Red flag:** custom edge-pan gestures, custom full-screen pagers, or row swipe actions interfere with the back gesture.
- **Red flag:** a custom nav bar is replacing system behavior that users already expect.
- **Red flag:** fancy transitions exist on screens where they do not improve understanding.

### Why this matters

UIKit now exposes both the classic edge-swipe pop gesture and a broader content-area back swipe via `interactiveContentPopGestureRecognizer`. Apple also notes that swipe actions can block it and custom gestures may need explicit failure requirements. That makes gesture conflict a real quality issue in modern apps. [4][6]

---

## B. Tabs, top-level structure, and search

### What good looks like

- Tabs are only used for top-level sections.
- Search is placed where the system expects it.
- You let the tab and bar system do the heavy lifting instead of recreating segmented navigation everywhere.

### Check each root section

- [ ] Top-level destinations are in a standard tab bar when appropriate.
- [ ] The tab structure is stable and not overloaded.
- [ ] Search is integrated with the system search APIs, rather than a custom fake search bar.
- [ ] You are not using persistent bottom chrome for actions that only matter on one screen.
- [ ] On scrolling content, bar behavior feels native rather than pinned and rigid.

### What to flag

- **Red flag:** a custom bottom bar duplicates a tab bar and loses standard motion/selection behavior.
- **Red flag:** a screen-specific CTA lives in the app-wide tab region.
- **Red flag:** search is hand-built when `.searchable` or the platform search presentation would work.

### Why this matters

Apple's WWDC 2025 guidance calls out major updates to tab views, bars, and search, including floating/minimizing tab behavior and better toolbar integration for search depending on available space and platform context. [2][3]

---

## C. Sheets, popovers, alerts, menus, and dialogs

### What good looks like

- You use the system presentation type that matches the job.
- Presentations feel attached to the thing that launched them.
- Alerts and dialogs are used sparingly and for the right level of severity.

### Check each transient interaction

- [ ] Uses `sheet`, `popover`, alert, confirmation dialog, or menu instead of a custom modal whenever possible.
- [ ] The source view or bar item is specified when anchoring matters.
- [ ] You are not using full-screen custom overlays for things that should be a menu, popover, or sheet.
- [ ] The user can dismiss or back out in the standard expected way.
- [ ] Destructive actions use system patterns and labeling.

### What to flag

- **Red flag:** action menus are implemented as custom half-screens.
- **Red flag:** a popover-capable action opens a generic centered modal instead.
- **Red flag:** multiple home-grown overlay systems coexist and all behave slightly differently.

### Why this matters

Apple's Liquid Glass overview says modal views like sheets and action sheets adopt the material automatically, with updated geometry and presentation feel. WWDC guidance also emphasizes source-linked presentations and transitions so UI appears to come from a known origin instead of appearing from nowhere. [2][7]

---

## D. Bars, toolbars, and chrome

### What good looks like

- Bars float lightly above content.
- Related toolbar actions are grouped clearly.
- You are not painting extra backgrounds to force hierarchy.

### Check each screen with top or bottom chrome

- [ ] Uses system navigation bars, tab bars, and toolbars rather than recreating them.
- [ ] Old opaque or blur-heavy bar backgrounds have been removed if they are no longer needed.
- [ ] Toolbar actions are grouped by relationship, not just packed together.
- [ ] You are not mixing unrelated actions into one visual cluster.
- [ ] Scroll-edge behavior feels natural and improves legibility.

### What to flag

- **Red flag:** custom bar backgrounds, borders, shadows, or permanent tint overlays are still present from pre-Liquid-Glass styling.
- **Red flag:** toolbar buttons are all jammed into one cluster so nothing has hierarchy.
- **Red flag:** the screen has both custom floating controls and standard bars fighting each other.

### Why this matters

Apple's design and UIKit guidance explicitly says many older bar customizations can interfere with the updated glass appearance. In SwiftUI, `ToolbarSpacer` exists specifically to create visual grouping inside glass toolbars, and Apple highlights `scrollEdgeEffectStyle` as part of refining the effect. [2][3][8][9]

---

## E. Custom Liquid Glass surfaces

### What good looks like

- You use custom glass only when standard controls are not enough.
- Custom glass elements feel like siblings of system controls, not decorative stickers.
- Related glass surfaces are grouped for coherence and performance.

### Check each custom floating control or branded component

- [ ] You tried a standard control first.
- [ ] The glass effect is on the control surface, not sprinkled onto inner subviews.
- [ ] Related glass items are grouped with `GlassEffectContainer` when appropriate.
- [ ] Morphing or continuity uses `glassEffectID` when relevant.
- [ ] The control remains legible over varied backgrounds.

### What to flag

- **Red flag:** glass is applied everywhere just because it looks new.
- **Red flag:** nested blur, custom shadow, frosted background, and tint stack on top of each other.
- **Red flag:** the same custom glass button style appears in situations where a standard button or toolbar item would be better.

### Why this matters

Apple's custom glass documentation says to use `glassEffect` for custom views, prefer the regular glass variant by default, and use `GlassEffectContainer` for multiple views both for rendering performance and coordinated morphing. `glassEffectID` is part of that coordinated animation story. [5][10][11][12]

---

## F. Content flowing under chrome

### What good looks like

- Content feels immersive under bars, sidebars, or inspectors.
- Large imagery and hero surfaces extend gracefully under system areas.
- You are using native edge behavior instead of hard cutoffs.

### Check each content-heavy screen

- [ ] Hero images or large content surfaces extend naturally under sidebars or bars where appropriate.
- [ ] You are not using awkward clipped rectangles where the system could provide a smoother extension.
- [ ] Scroll-edge fading and legibility feel intentional.
- [ ] Custom accessory bars use native safe-area placement rather than absolute overlays.

### What to flag

- **Red flag:** imagery stops abruptly at the safe area when a background extension would look better.
- **Red flag:** sticky overlays are absolutely positioned over content instead of using safe-area-aware APIs.
- **Red flag:** the first content cell is hidden under a floating control with no proper inset strategy.

### Why this matters

Apple added `backgroundExtensionEffect()` to extend content surfaces more naturally and `safeAreaBar(...)` for custom bars that belong in the safe area system. These are exactly the kinds of details that make an app feel like it was designed for the platform instead of merely placed on it. [13][14][15]

---

## G. Motion and continuity

### What good looks like

- Motion explains state change.
- Animation origins are obvious.
- Nothing moves just to look expensive.

### Check each animated transition

- [ ] Large transitions have a visible source and destination.
- [ ] Zoom transitions are used mainly for expanding cards, thumbnails, or list items into detail.
- [ ] Sheet and popover presentation motion matches the source control when possible.
- [ ] Motion supports understanding rather than showing off.
- [ ] Reduce Motion testing does not break the experience.

### What to flag

- **Red flag:** every screen transition zooms.
- **Red flag:** custom springy overlays do not match native timing or interruption behavior.
- **Red flag:** different parts of the app use different motion languages.

### Why this matters

Apple's navigation transition APIs are specifically about making appearing content zoom from a given source. This works best when the source relationship is obvious and the motion communicates continuity rather than novelty. [16]

---

## H. Accessibility and resilience

### What good looks like

- The UI remains legible with accessibility settings enabled.
- Glass still works in dark mode, high contrast, and motion-reduced contexts.
- The app does not depend on translucency to communicate meaning.

### Check across the app

- [ ] Test with **Reduce Transparency**.
- [ ] Test with **Increase Contrast**.
- [ ] Test with **Reduce Motion**.
- [ ] Test light and dark mode.
- [ ] Test Dynamic Type at large sizes.
- [ ] Test VoiceOver focus order around floating bars and custom glass controls.

### What to flag

- **Red flag:** clear or highly transparent glass becomes unreadable over photography or maps.
- **Red flag:** important state is only expressed through translucency or blur.
- **Red flag:** custom floating controls block content or accessibility focus.

### Why this matters

Apple's guidance around glass emphasizes legibility and careful use of clearer variants. The regular variant is the safer default, and accessibility settings must still preserve comprehension and contrast. [5][17]

---

# Part 2 - How to style an app in a Liquid Glass way

## Start here

The Liquid Glass style is **not**:

- blur everywhere
- rounded translucent cards everywhere
- all-brand-color chrome
- overlaying floating controls on every screen

The Liquid Glass style **is**:

- standard structure first
- content-first surfaces
- lighter chrome
- stronger grouping
- clearer source-to-destination transitions
- careful use of custom glass only where the system controls are not enough

Apple's design videos repeatedly push this point: use the system-provided structures and let the material emerge from them. [1][2][3]

---

## The styling hierarchy

### Level 1 - Use native structure
Do this before anything else.

- Use standard nav containers.
- Use standard bars.
- Use standard tabs.
- Use standard sheets, popovers, menus, and alerts.
- Use native search.

This gets you the biggest "free" gain. [1][2][3]

### Level 2 - Remove compensating customizations
These were often reasonable before, but now may make the app feel older.

Remove or reassess:

- opaque bar fills
- fake blur layers
- extra separators and borders on bars
- always-on shadows around chrome
- giant filled navigation headers if they duplicate system hierarchy
- bottom overlays that mimic bars but are not bars

Apple explicitly warns that bar background customization can interfere with the new look. [2]

### Level 3 - Group controls instead of decorating them
Use placement and grouping to create hierarchy.

- Put related actions together.
- Separate unrelated actions.
- Use toolbar placements and `ToolbarSpacer` rather than manual background capsules around everything.
- Prefer one clear primary action over several visually identical competing actions.

This is one of the most underused parts of the new system. [8][9]

### Level 4 - Let content run under chrome
The glass effect looks best when bars sit above meaningful content.

- Feed views, maps, imagery, and long lists benefit from content flowing under bars.
- Hero images can use `backgroundExtensionEffect()` where appropriate.
- Use scroll-edge behavior to improve legibility instead of adding heavy permanent backgrounds.

[13][15]

### Level 5 - Add custom glass sparingly
Only do this when it improves the product, not just the screenshot.

Good candidates:

- a floating playback control
- a compact map action cluster
- a contextual editing platter
- a branded but system-like quick action control

Bad candidates:

- every card in a feed
- every settings row
- every CTA button in the app
- stacked custom frosted panels

[5][10][11]

---

## Design rules for custom glass

### 1. Prefer regular glass first
Use the default/regular glass variant first. Only use clearer variants if you have verified legibility over the full range of real backgrounds in your app. [5][17]

### 2. Apply glass to the surface, not the internals
The effect should belong to the control or platter itself. Do not put separate mini-glass treatments on the label, icon, badge, and container all at once. [3][5]

### 3. Avoid blur stacks
Do not combine:

- material background
- custom blur
- translucent fill
- large shadow
- bright border

on the same element unless you have a very good reason. The result usually looks less native, not more.

### 4. Use one custom glass moment per screen
Most screens only need one dominant custom glass interaction, if any.

### 5. Keep brand color restrained
Tint should support hierarchy, not replace it. Over-tinting chrome makes the app feel like a themed skin instead of an iOS app.

### 6. Use source continuity for motion
If a control opens a detail view, sheet, or popover, give the motion a clear origin. That is often more important than the material itself. [2][16]

---

## SwiftUI implementation path

### Good first moves

1. Move core screens to `NavigationStack` if you have not already.
2. Replace custom search bars with `.searchable` where possible.
3. Revisit every `.toolbar` and group actions intentionally.
4. Remove manual bar backgrounds that are no longer needed.
5. Add source-linked navigation or presentation only where it improves clarity.
6. Use `backgroundExtensionEffect()` on qualifying hero surfaces.
7. Only then consider `glassEffect`, `GlassEffectContainer`, and `glassEffectID` for custom controls.

### APIs to look at

- `NavigationStack`
- `.navigationTransition(...)`
- `.matchedTransitionSource(...)`
- `.searchable(...)`
- `.toolbar { ... }`
- `ToolbarSpacer`
- `.scrollEdgeEffectStyle(...)`
- `.backgroundExtensionEffect()`
- `.safeAreaBar(...)`
- `.glassEffect(...)`
- `GlassEffectContainer`
- `.glassEffectID(..., in: ...)`

Relevant Apple docs and sessions: [1][3][5][8][10][11][13][14][16]

---

## UIKit implementation path

### Good first moves

1. Audit custom `UINavigationBarAppearance` and `UITabBarAppearance` usage.
2. Remove background colors, custom blur, or overlays that override the new defaults without a strong reason.
3. Confirm sheets, popovers, menus, and dialogs are using system presentation controllers.
4. Make sure source views/bar items are provided for anchored presentations and zoom transitions where relevant.
5. Test back-swipe behavior with any horizontal gestures in your content.
6. Introduce custom glass only for high-value controls that standard UIKit components cannot represent well.

### APIs and areas to inspect

- `UINavigationController`
- `interactivePopGestureRecognizer`
- `interactiveContentPopGestureRecognizer`
- `UITabBarController`
- `UIBarAppearance`
- system sheet / popover / menu APIs
- view controller zoom transition APIs

Relevant Apple docs and sessions: [2][4][6][7][18]

---

# Part 3 - A practical screen review template

Copy this section for each screen in your app.

## Screen name: ____________________

### Purpose
What is this screen for in one sentence?

### Current structure
- Navigation container:
- Bar type:
- Search:
- Presentation types used:
- Custom gestures:
- Custom floating controls:

### Audit

#### Native structure
- [ ] Uses standard navigation
- [ ] Uses standard bars
- [ ] Uses standard presentation types
- [ ] Uses native search

#### Free interaction wins
- [ ] Back swipe works cleanly
- [ ] Popovers/sheets/menus feel source-linked
- [ ] Toolbar grouping feels intentional
- [ ] Scroll behavior feels native

#### Liquid Glass fit
- [ ] Content benefits from floating chrome
- [ ] Old background hacks removed
- [ ] No blur stacks
- [ ] Any custom glass has a clear purpose
- [ ] Legibility survives real content backgrounds

#### Accessibility
- [ ] Dark mode works
- [ ] Increase Contrast works
- [ ] Reduce Transparency works
- [ ] Reduce Motion works
- [ ] Large Dynamic Type works

### Verdict
Mark one:

- [ ] Already taking good advantage of the system
- [ ] Missing easy wins
- [ ] Partly modern but fighting the system in places
- [ ] Needs structural cleanup before visual polish

### Next actions
1.
2.
3.

---

# Part 4 - Common anti-patterns to remove first

These usually produce the biggest quality jump for the least effort.

1. **Custom bar fills everywhere**  
   Old opaque nav and tab bar backgrounds often make the app feel heavier and older than it needs to.

2. **Fake search UI**  
   A styled text field pretending to be search often misses placement, behavior, and focus affordances the system already solves.

3. **Full-screen custom overlays for small tasks**  
   Menus, confirmation dialogs, popovers, and sheets now look and feel better than many home-grown alternatives.

4. **Too many floating controls**  
   One strong contextual platter is better than three decorative ones.

5. **Blur stack design**  
   If you have custom blur + translucent fill + big shadow + border + color overlay, simplify.

6. **Gesture conflicts**  
   If swipe-back is inconsistent, users feel it immediately.

7. **Overusing zoom transitions**  
   They are best when expanding something recognizable into its detail, not as the default transition for everything.

8. **Brand tint on all chrome**  
   Use tint to support the system, not replace it.

---

# Part 5 - What to send me next for an app-specific audit

If you want a real audit of your app rather than a generic checklist, send any of these:

- screen recordings of your main flows
- screenshots of 5 to 10 important screens
- SwiftUI view code for key screens
- UIKit view controller code and appearance setup
- a list of custom gestures, bars, sheets, and overlays

The highest-value screens to review first are usually:

1. home/root screen
2. main list or feed
3. detail screen
4. search flow
5. creation/edit flow
6. settings or account area

---

# References

[1] Build a SwiftUI app with the new design - WWDC25  
https://developer.apple.com/videos/play/wwdc2025/323/

[2] Build a UIKit app with the new design - WWDC25  
https://developer.apple.com/videos/play/wwdc2025/284/

[3] Get to know the new design system - WWDC25  
https://developer.apple.com/videos/play/wwdc2025/356/

[4] interactiveContentPopGestureRecognizer - Apple Developer Documentation  
https://developer.apple.com/documentation/uikit/uinavigationcontroller/interactivecontentpopgesturerecognizer

[5] Applying Liquid Glass to custom views - Apple Developer Documentation  
https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views

[6] interactivePopGestureRecognizer - Apple Developer Documentation  
https://developer.apple.com/documentation/uikit/uinavigationcontroller/interactivepopgesturerecognizer

[7] Adopting Liquid Glass - Apple Developer Documentation  
https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass

[8] ToolbarSpacer - Apple Developer Documentation  
https://developer.apple.com/documentation/SwiftUI/ToolbarSpacer

[9] SwiftUI updates - Apple Developer Documentation  
https://developer.apple.com/documentation/updates/swiftui

[10] glassEffect(_:in:) - Apple Developer Documentation  
https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29

[11] GlassEffectContainer - Apple Developer Documentation  
https://developer.apple.com/documentation/swiftui/glasseffectcontainer

[12] glassEffectID(_:in:) - Apple Developer Documentation  
https://developer.apple.com/documentation/swiftui/view/glasseffectid%28_%3Ain%3A%29

[13] backgroundExtensionEffect() - Apple Developer Documentation  
https://developer.apple.com/documentation/SwiftUI/View/backgroundExtensionEffect%28%29

[14] safeAreaBar(edge:alignment:spacing:content:) - Apple Developer Documentation  
https://developer.apple.com/documentation/swiftui/view/safeareabar%28edge%3Aalignment%3Aspacing%3Acontent%3A%29

[15] Landmarks: Building an app with Liquid Glass - Apple Developer Documentation  
https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass

[16] NavigationTransition / ZoomNavigationTransition - Apple Developer Documentation  
https://developer.apple.com/documentation/swiftui/navigationtransition
https://developer.apple.com/documentation/swiftui/zoomnavigationtransition

[17] Meet Liquid Glass - WWDC25  
https://developer.apple.com/videos/play/wwdc2025/219/

[18] What's new in UIKit - WWDC25  
https://developer.apple.com/videos/play/wwdc2025/243/
