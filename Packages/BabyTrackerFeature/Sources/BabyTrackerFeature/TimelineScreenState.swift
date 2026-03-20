import Foundation

public struct TimelineScreenState: Equatable, Sendable {
    public let selectedDay: Date
    public let dayTitle: String
    public let showsJumpToToday: Bool
    public let canMoveToNextDay: Bool
    public let rows: [TimelineEventRowViewState]
    public let emptyStateTitle: String
    public let emptyStateMessage: String
    public let syncMessage: String?

    public init(
        selectedDay: Date,
        dayTitle: String,
        showsJumpToToday: Bool,
        canMoveToNextDay: Bool,
        rows: [TimelineEventRowViewState],
        emptyStateTitle: String,
        emptyStateMessage: String,
        syncMessage: String?
    ) {
        self.selectedDay = selectedDay
        self.dayTitle = dayTitle
        self.showsJumpToToday = showsJumpToToday
        self.canMoveToNextDay = canMoveToNextDay
        self.rows = rows
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
        self.syncMessage = syncMessage
    }
}
