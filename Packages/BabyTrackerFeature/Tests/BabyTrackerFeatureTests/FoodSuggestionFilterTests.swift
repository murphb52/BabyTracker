@testable import BabyTrackerFeature
import Testing

struct FoodSuggestionFilterTests {
    private let names = ["Avocado", "Banana", "Porridge", "Yoghurt", "Purée", "Sweet Potato", "Broccoli", "Pear", "Pasta", "Apple"]

    @Test
    func emptyQueryReturnsFirstSuggestionsUpToLimit() {
        let result = FoodSuggestionFilter.suggestions(from: names, matching: "  ")

        #expect(result == Array(names.prefix(8)))
    }

    @Test
    func queryMatchesCaseInsensitively() {
        let result = FoodSuggestionFilter.suggestions(from: names, matching: "BAN")

        #expect(result == ["Banana"])
    }

    @Test
    func prefixMatchesComeBeforeOtherMatches() {
        let result = FoodSuggestionFilter.suggestions(from: names, matching: "p")

        #expect(result == ["Porridge", "Purée", "Pear", "Pasta", "Sweet Potato", "Apple"])
    }

    @Test
    func noMatchesReturnsEmptyList() {
        let result = FoodSuggestionFilter.suggestions(from: names, matching: "kiwi")

        #expect(result.isEmpty)
    }
}
