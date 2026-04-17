import BabyTrackerDomain
import Foundation

/// Produces the current-status card state for the home screen by composing
/// the per-type feed calculators, `LastNappySummaryCalculator`, and `LastSleepSummaryCalculator`.
public enum BuildCurrentStatusViewStateUseCase {
    public static func execute(
        events: [BabyEvent],
        child: Child,
        activeSleep: SleepEvent? = nil,
        day: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> CurrentStatusCardViewState {
        let feedSummary = FeedSummaryCalculator.makeSummary(
            from: events,
            preferredFeedVolumeUnit: child.preferredFeedVolumeUnit,
            on: day,
            calendar: calendar
        )
        let lastNappy = LastNappySummaryCalculator.makeSummary(from: events)
        let lastSleep = LastSleepSummaryCalculator.makeSummary(from: events, activeSleep: activeSleep)
        let lastBreastFeed = lastBreastFeedSummary(from: events)
        let lastBottleFeed = lastBottleFeedSummary(from: events, preferredFeedVolumeUnit: child.preferredFeedVolumeUnit)

        return CurrentStatusCardViewState(
            lastSleep: lastSleep,
            lastBreastFeed: lastBreastFeed,
            lastBottleFeed: lastBottleFeed,
            feedsTodayCount: feedSummary?.feedsTodayCount ?? 0,
            lastNappy: lastNappy
        )
    }

    private static func lastBreastFeedSummary(from events: [BabyEvent]) -> LastEventSummaryViewState? {
        let breastFeeds = events.compactMap { event -> BreastFeedEvent? in
            guard case let .breastFeed(feed) = event else { return nil }
            return feed
        }

        guard let last = breastFeeds.max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt }) else {
            return nil
        }

        return LastEventSummaryViewState(
            kind: .breastFeed,
            title: BabyEventPresentation.title(for: .breastFeed),
            detailText: BabyEventPresentation.detailText(for: .breastFeed(last)),
            occurredAt: last.metadata.occurredAt
        )
    }

    private static func lastBottleFeedSummary(
        from events: [BabyEvent],
        preferredFeedVolumeUnit: FeedVolumeUnit
    ) -> LastEventSummaryViewState? {
        let bottleFeeds = events.compactMap { event -> BottleFeedEvent? in
            guard case let .bottleFeed(feed) = event else { return nil }
            return feed
        }

        guard let last = bottleFeeds.max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt }) else {
            return nil
        }

        return LastEventSummaryViewState(
            kind: .bottleFeed,
            title: BabyEventPresentation.title(for: .bottleFeed),
            detailText: BabyEventPresentation.detailText(
                for: .bottleFeed(last),
                preferredFeedVolumeUnit: preferredFeedVolumeUnit
            ),
            occurredAt: last.metadata.occurredAt
        )
    }
}
