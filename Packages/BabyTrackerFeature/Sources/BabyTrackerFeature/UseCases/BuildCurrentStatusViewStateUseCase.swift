import BabyTrackerDomain
import Foundation

/// Produces the current-status card state for the home screen by composing
/// `FeedSummaryCalculator` and `LastNappySummaryCalculator`.
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

        return CurrentStatusCardViewState(
            lastSleep: lastSleep,
            timeSinceLastFeedAt: feedSummary?.lastFeedAt,
            feedsTodayCount: feedSummary?.feedsTodayCount ?? 0,
            timeSinceLastNappyAt: lastNappy?.occurredAt
        )
    }
}
