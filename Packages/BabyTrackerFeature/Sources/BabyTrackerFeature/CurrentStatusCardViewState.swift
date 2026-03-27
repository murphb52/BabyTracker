import Foundation

public struct CurrentStatusCardViewState: Equatable, Sendable {
    public let timeSinceLastFeedAt: Date?
    public let feedsTodayCount: Int
    public let timeSinceLastNappyAt: Date?

    public init(
        timeSinceLastFeedAt: Date?,
        feedsTodayCount: Int,
        timeSinceLastNappyAt: Date?
    ) {
        self.timeSinceLastFeedAt = timeSinceLastFeedAt
        self.feedsTodayCount = feedsTodayCount
        self.timeSinceLastNappyAt = timeSinceLastNappyAt
    }
}
