import Foundation

public struct CurrentStateSummaryViewState: Equatable, Sendable {
    public let lastEvent: LastEventSummaryViewState
    public let lastFeed: FeedStatusViewState?

    public init(
        lastEvent: LastEventSummaryViewState,
        lastFeed: FeedStatusViewState?
    ) {
        self.lastEvent = lastEvent
        self.lastFeed = lastFeed
    }
}
