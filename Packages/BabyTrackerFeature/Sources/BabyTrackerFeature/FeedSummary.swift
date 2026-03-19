import BabyTrackerDomain
import Foundation

public struct FeedSummary: Equatable, Sendable {
    public let lastFeedKind: BabyEventKind
    public let lastFeedAt: Date
    public let feedsTodayCount: Int

    public init(
        lastFeedKind: BabyEventKind,
        lastFeedAt: Date,
        feedsTodayCount: Int
    ) {
        self.lastFeedKind = lastFeedKind
        self.lastFeedAt = lastFeedAt
        self.feedsTodayCount = feedsTodayCount
    }
}
