import BabyTrackerDomain
import Foundation

public struct FeedSummary: Equatable, Sendable {
    public let lastFeedKind: BabyEventKind
    public let lastFeedTitle: String
    public let lastFeedDetailText: String?
    public let lastFeedAt: Date
    public let feedsTodayCount: Int

    public init(
        lastFeedKind: BabyEventKind,
        lastFeedTitle: String,
        lastFeedDetailText: String?,
        lastFeedAt: Date,
        feedsTodayCount: Int
    ) {
        self.lastFeedKind = lastFeedKind
        self.lastFeedTitle = lastFeedTitle
        self.lastFeedDetailText = lastFeedDetailText
        self.lastFeedAt = lastFeedAt
        self.feedsTodayCount = feedsTodayCount
    }
}
