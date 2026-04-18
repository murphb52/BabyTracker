# 096 - Bottle feed sheet add 100ml preset

## Goal
Add a 100 ml quick-select amount option to the bottle feed editor sheet so caregivers can log that common amount with one tap.

## Approach
1. Locate the quick amount preset list used by `BottleFeedEditorSheetView` for milliliter mode.
2. Insert `100` into the milliliter preset options while preserving the existing ascending order.
3. Run targeted checks to confirm the project still builds/tests cleanly for the touched module.

- [x] Complete
