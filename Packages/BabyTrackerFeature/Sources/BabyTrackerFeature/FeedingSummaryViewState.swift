import BabyTrackerDomain
import Foundation

public struct FeedingSummaryViewState: Equatable, Sendable {
    public let lastFeedTitle: String
    public let lastFeedTimestamp: String
    public let feedsTodayText: String

    public init(summary: FeedSummary) {
        switch summary.lastFeedKind {
        case .breastFeed:
            lastFeedTitle = "Breast Feed"
        case .bottleFeed:
            lastFeedTitle = "Bottle Feed"
        case .sleep:
            lastFeedTitle = "Sleep"
        case .nappy:
            lastFeedTitle = "Nappy"
        }

        lastFeedTimestamp = summary.lastFeedAt.formatted(
            date: .abbreviated,
            time: .shortened
        )
        feedsTodayText = "\(summary.feedsTodayCount)"
    }
}
