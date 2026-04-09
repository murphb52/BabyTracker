import BabyTrackerDomain
import Foundation

public enum LastSleepSummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent],
        activeSleep: SleepEvent? = nil
    ) -> LastSleepSummaryViewState? {
        guard let summary = FindLatestEventUseCases.latestSleepSummary(
            from: events,
            activeSleep: activeSleep
        ) else {
            return nil
        }

        return LastSleepSummaryViewState(
            isActive: summary.isActive,
            startedAt: summary.startedAt,
            endedAt: summary.endedAt
        )
    }
}
