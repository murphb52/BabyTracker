import Foundation

public struct EventHistoryScreenState: Equatable, Sendable {
    public let events: [EventCardViewState]
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public init(
        events: [EventCardViewState],
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.events = events
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
