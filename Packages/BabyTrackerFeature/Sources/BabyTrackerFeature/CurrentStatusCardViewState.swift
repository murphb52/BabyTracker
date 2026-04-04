import Foundation

public struct CurrentStatusCardViewState: Equatable, Sendable {
    public let lastSleep: LastSleepSummaryViewState?
    public let timeSinceLastFeedAt: Date?
    public let feedsTodayCount: Int
    public let timeSinceLastNappyAt: Date?

    public init(
        lastSleep: LastSleepSummaryViewState?,
        timeSinceLastFeedAt: Date?,
        feedsTodayCount: Int,
        timeSinceLastNappyAt: Date?
    ) {
        self.lastSleep = lastSleep
        self.timeSinceLastFeedAt = timeSinceLastFeedAt
        self.feedsTodayCount = feedsTodayCount
        self.timeSinceLastNappyAt = timeSinceLastNappyAt
    }
}
