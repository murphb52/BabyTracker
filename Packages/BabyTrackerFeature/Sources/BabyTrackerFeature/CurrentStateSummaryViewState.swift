import Foundation

public struct CurrentStateSummaryViewState: Equatable, Sendable {
    public let lastEvent: LastEventSummaryViewState
    public let lastFeed: FeedStatusViewState?
    public let lastNappy: LastNappySummaryViewState?

    public init(
        lastEvent: LastEventSummaryViewState,
        lastFeed: FeedStatusViewState?,
        lastNappy: LastNappySummaryViewState?
    ) {
        self.lastEvent = lastEvent
        self.lastFeed = lastFeed
        self.lastNappy = lastNappy
    }
}
