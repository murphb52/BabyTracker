import Foundation

public struct EventHistoryScreenState: Equatable, Sendable {
    public let events: [EventCardViewState]
    public let filterIsActive: Bool
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public init(
        events: [EventCardViewState],
        filterIsActive: Bool,
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.events = events
        self.filterIsActive = filterIsActive
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
