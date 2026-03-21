import Foundation

public struct HomeScreenState: Equatable, Sendable {
    public let currentStateSummary: CurrentStateSummaryViewState?
    public let recentEvents: [EventCardViewState]
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public init(
        currentStateSummary: CurrentStateSummaryViewState?,
        recentEvents: [EventCardViewState],
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.currentStateSummary = currentStateSummary
        self.recentEvents = recentEvents
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
