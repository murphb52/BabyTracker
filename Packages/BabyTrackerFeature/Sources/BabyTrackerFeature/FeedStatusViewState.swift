import BabyTrackerDomain
import Foundation

public struct FeedStatusViewState: Equatable, Sendable {
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String?
    public let lastFeedAt: Date
    public let feedsTodayCount: Int

    public init(summary: FeedSummary) {
        kind = summary.lastFeedKind
        title = summary.lastFeedTitle
        detailText = summary.lastFeedDetailText
        lastFeedAt = summary.lastFeedAt
        feedsTodayCount = summary.feedsTodayCount
    }
}
