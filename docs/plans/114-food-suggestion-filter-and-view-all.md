# 114 - Food Suggestion Filter and View All Foods

GitHub issue: #288

## Goal

Make the Food logging sheet faster to use:

- the food name suggestion chips narrow as the caregiver types
- a "View all foods" button opens a sheet listing every food the child has had

## Approach

1. Let `FetchRecentFoodNamesUseCase` return every distinct name when `limit` is `nil`. `AppModel.recentFoodNames()` asks for all names; the editor decides how many chips to show.
2. Add a small pure `FoodSuggestionFilter` in the feature package:
   - empty query returns the first 8 suggestions (today's behaviour)
   - otherwise returns suggestions containing the query, case-insensitive, with prefix matches first, capped at 8
3. `FoodEditorSheetView` uses the filter for its chips and hides the chip row when nothing matches.
4. Add `FoodHistoryListView`: an alphabetical, searchable list of all foods the child has had. Tapping a food fills the name field and dismisses. It is presented with `.medium` and `.large` detents so it opens at half height and only goes full screen when pulled up.
5. Tests for the unlimited use case fetch and the suggestion filter. Previews for the new list view and an updated editor preview.

- [ ] Complete
