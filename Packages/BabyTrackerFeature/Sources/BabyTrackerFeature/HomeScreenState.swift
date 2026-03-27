import Foundation

public struct HomeScreenState: Equatable, Sendable {
    public let currentSleep: CurrentSleepCardViewState?
    public let currentStatus: CurrentStatusCardViewState
    public let recentEvents: [EventCardViewState]
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public init(
        currentSleep: CurrentSleepCardViewState?,
        currentStatus: CurrentStatusCardViewState,
        recentEvents: [EventCardViewState],
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.currentSleep = currentSleep
        self.currentStatus = currentStatus
        self.recentEvents = recentEvents
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
