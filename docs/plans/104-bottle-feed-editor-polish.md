# 104 - Bottle feed editor polish

## Goal
Polish the bottle feed amount picking flow so custom amounts are easier to discover and edit. This includes clearer customise affordances, better focus behavior for custom entry, explanatory copy for suggestions, and animated add/remove updates in the amount customizer.

## Approach
1. Update `BottleFeedEditorSheetView` to make the amount section header clearer, add explanatory suggested copy, and focus the custom amount field when the user chooses the custom option.
2. Update `BottleAmountCustomizerView` so adding and removing quick amounts animates the list changes while keeping the implementation simple and explicit.
3. Refresh previews where useful and run targeted verification for the touched package.

- [x] Complete
