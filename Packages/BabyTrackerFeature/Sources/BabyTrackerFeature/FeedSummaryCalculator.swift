import BabyTrackerDomain
import Foundation

public enum FeedSummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent],
        on day: Date = .now,
        calendar: Calendar = .current
    ) -> FeedSummary? {
        let feedEvents = events.filter { event in
            event.kind == .breastFeed || event.kind == .bottleFeed
        }

        guard let lastFeed = feedEvents.max(by: { left, right in
            left.metadata.occurredAt < right.metadata.occurredAt
        }) else {
            return nil
        }

        let feedsTodayCount = feedEvents.filter { event in
            calendar.isDate(event.metadata.occurredAt, inSameDayAs: day)
        }.count

        return FeedSummary(
            lastFeedKind: lastFeed.kind,
            lastFeedTitle: BabyEventPresentation.title(for: lastFeed),
            lastFeedDetailText: BabyEventPresentation.detailText(for: lastFeed),
            lastFeedAt: lastFeed.metadata.occurredAt,
            feedsTodayCount: feedsTodayCount
        )
    }
}
