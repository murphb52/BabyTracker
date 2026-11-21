import Foundation

/// Narrows the food name suggestion chips to the names matching what the caregiver has typed.
enum FoodSuggestionFilter {
    static let defaultLimit = 8

    /// Returns suggestions containing `query` (case-insensitive), with names that start with the
    /// query listed first. An empty query keeps the original order. Results are capped at `limit`.
    static func suggestions(from names: [String], matching query: String, limit: Int = defaultLimit) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return Array(names.prefix(limit)) }

        let matches = names.filter { $0.localizedCaseInsensitiveContains(trimmedQuery) }
        let prefixMatches = matches.filter { startsWith($0, trimmedQuery) }
        let otherMatches = matches.filter { !startsWith($0, trimmedQuery) }
        return Array((prefixMatches + otherMatches).prefix(limit))
    }

    private static func startsWith(_ name: String, _ query: String) -> Bool {
        name.range(of: query, options: [.caseInsensitive, .anchored]) != nil
    }
}
