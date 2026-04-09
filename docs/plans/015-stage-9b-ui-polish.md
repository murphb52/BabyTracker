# 015 Stage 9B: Timeline, Status, Profile, and Anchored Interaction Polish

## Summary

Polish the child workspace in six areas:

1. Timeline event blocks always show meaningful text, even in the smallest blocks.
2. Timeline day navigation becomes a horizontally paged day experience instead of a drag gesture.
3. Event icons are refreshed and centralized so every surface uses the same stronger visual language.
4. Current Status becomes a more prominent card with clearer hierarchy.
5. Profile becomes iOS Settings-style, with top-level summary rows that push into dedicated detail screens.
6. Remove unanchored pop-up interactions across the child workspace and replace them with anchored or inline alternatives.

## Implementation

1. Rework timeline state to use paged day models within a visible week.
2. Build week-backed timeline pages in `AppModel` and keep the selected day as the source of truth.
3. Ensure every timeline block always renders event text, even at the smallest height.
4. Replace gesture-based timeline day switching with native horizontal paging.
5. Refresh event icons and centralize symbol mapping.
6. Upgrade Current Status into a more prominent feature card.
7. Convert Profile into an iOS Settings-style overview with dedicated detail screens.
8. Add dedicated detail screens for child details, sharing, sync, and archive.
9. Add manual sync refresh support to `AppModel`.
10. Remove unanchored confirmation dialogs from the child workspace.
11. Replace delete confirmations with anchored inline confirmation UI on Home, Events, and Timeline.
12. Replace nappy quick log with an anchored menu on the Home quick-log tile.

## Defaults

- Timeline day navigation uses horizontally paged days.
- The visible timeline pages are week-based and rebuild when selection crosses week boundaries.
- Event icon updates stay within SF Symbols.
- Profile detail screens are grouped by area.
- Anchored interactions are implemented as source-attached menus or inline confirmation controls.

- [x] Complete
