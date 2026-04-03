import BabyTrackerDomain
import Foundation

/// Produces the current-status card state for the home screen by composing
/// `FeedSummaryCalculator` and `LastNappySummaryCalculator`.
public enum BuildCurrentStatusViewStateUseCase {
    public static func execute(
        events: [BabyEvent],
        child: Child,
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

        return CurrentStatusCardViewState(
            timeSinceLastFeedAt: feedSummary?.lastFeedAt,
            feedsTodayCount: feedSummary?.feedsTodayCount ?? 0,
            timeSinceLastNappyAt: lastNappy?.occurredAt
        )
    }
}
