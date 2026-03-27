import BabyTrackerDomain
import Foundation

public struct EventHistoryScreenState: Equatable, Sendable {
    public let events: [EventCardViewState]
    public let filterIsActive: Bool
    public let activeFilter: EventFilter
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public init(
        events: [EventCardViewState],
        filterIsActive: Bool,
        activeFilter: EventFilter,
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.events = events
        self.filterIsActive = filterIsActive
        self.activeFilter = activeFilter
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
