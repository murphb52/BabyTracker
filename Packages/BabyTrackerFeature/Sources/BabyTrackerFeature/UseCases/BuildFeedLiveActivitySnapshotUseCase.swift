import BabyTrackerDomain
import Foundation

/// Builds the `FeedLiveActivitySnapshot` used to update the lock-screen
/// Live Activity widget. Returns `nil` when there is no feed data yet.
public enum BuildFeedLiveActivitySnapshotUseCase {
    public static func execute(
        events: [BabyEvent],
        child: Child,
        activeSleep: SleepEvent?
    ) -> FeedLiveActivitySnapshot? {
        guard let summary = FeedSummaryCalculator.makeSummary(
            from: events,
            preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
        ) else {
            return nil
        }

        let lastSleep = LastSleepSummaryCalculator.makeSummary(
            from: events,
            activeSleep: activeSleep
        )
        let lastNappy = LastNappySummaryCalculator.makeSummary(from: events)

        return FeedLiveActivitySnapshot(
            childID: child.id,
            childName: child.name,
            lastFeedKind: summary.lastFeedKind,
            lastFeedAt: summary.lastFeedAt,
            lastSleepAt: lastSleep?.endedAt ?? lastSleep?.startedAt,
            activeSleepStartedAt: lastSleep?.isActive == true ? lastSleep?.startedAt : nil,
            lastNappyAt: lastNappy?.occurredAt
        )
    }
}
