import Foundation

public struct CurrentStatusCardViewState: Equatable, Sendable {
    public let lastSleep: LastSleepSummaryViewState?
    public let lastBreastFeed: LastEventSummaryViewState?
    public let lastBottleFeed: LastEventSummaryViewState?
    public let feedsTodayCount: Int
    public let lastNappy: LastNappySummaryViewState?

    public init(
        lastSleep: LastSleepSummaryViewState?,
        lastBreastFeed: LastEventSummaryViewState?,
        lastBottleFeed: LastEventSummaryViewState?,
        feedsTodayCount: Int,
        lastNappy: LastNappySummaryViewState?
    ) {
        self.lastSleep = lastSleep
        self.lastBreastFeed = lastBreastFeed
        self.lastBottleFeed = lastBottleFeed
        self.feedsTodayCount = feedsTodayCount
        self.lastNappy = lastNappy
    }
}
