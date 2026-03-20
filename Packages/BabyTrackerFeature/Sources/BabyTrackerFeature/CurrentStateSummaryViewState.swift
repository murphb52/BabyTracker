import Foundation

public struct CurrentStateSummaryViewState: Equatable, Sendable {
    public let lastEvent: LastEventSummaryViewState
    public let lastFeed: FeedStatusViewState?
    public let lastSleep: LastSleepSummaryViewState?
    public let lastNappy: LastNappySummaryViewState?

    public init(
        lastEvent: LastEventSummaryViewState,
        lastFeed: FeedStatusViewState?,
        lastSleep: LastSleepSummaryViewState?,
        lastNappy: LastNappySummaryViewState?
    ) {
        self.lastEvent = lastEvent
        self.lastFeed = lastFeed
        self.lastSleep = lastSleep
        self.lastNappy = lastNappy
    }
}
