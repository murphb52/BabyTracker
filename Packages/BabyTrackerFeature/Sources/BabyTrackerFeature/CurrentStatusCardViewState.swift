import Foundation

public struct CurrentStatusCardViewState: Equatable, Sendable {
    public let lastSleep: LastSleepSummaryViewState?
    public let lastBreastFeed: LastEventSummaryViewState?
    public let lastBottleFeed: LastEventSummaryViewState?
    public let feedsTodayCount: Int
    public let lastNappy: LastNappySummaryViewState?

    public var timeSinceLastFeedAt: Date? {
        switch (lastBreastFeed?.occurredAt, lastBottleFeed?.occurredAt) {
        case let (left?, right?):
            return max(left, right)
        case let (left?, nil):
            return left
        case let (nil, right?):
            return right
        case (nil, nil):
            return nil
        }
    }

    public var timeSinceLastNappyAt: Date? {
        lastNappy?.occurredAt
    }

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
