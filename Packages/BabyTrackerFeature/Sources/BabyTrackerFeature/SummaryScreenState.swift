import BabyTrackerDomain
import Foundation

public struct SummaryScreenState: Equatable, Sendable {
    public let events: [BabyEvent]
    public let emptyStateTitle: String
    public let emptyStateMessage: String

    public init(
        events: [BabyEvent],
        emptyStateTitle: String,
        emptyStateMessage: String
    ) {
        self.events = events
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
    }
}
