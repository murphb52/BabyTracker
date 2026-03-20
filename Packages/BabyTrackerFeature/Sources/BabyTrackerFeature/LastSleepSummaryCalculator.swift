import BabyTrackerDomain
import Foundation

public enum LastSleepSummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent],
        activeSleep: SleepEvent? = nil
    ) -> LastSleepSummaryViewState? {
        if let activeSleep {
            return LastSleepSummaryViewState(
                isActive: true,
                startedAt: activeSleep.startedAt,
                endedAt: nil
            )
        }

        let completedSleeps = events.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleepEvent) = event,
                  sleepEvent.endedAt != nil else {
                return nil
            }

            return sleepEvent
        }

        guard let lastSleep = completedSleeps.max(by: { left, right in
            (left.endedAt ?? left.startedAt) < (right.endedAt ?? right.startedAt)
        }) else {
            return nil
        }

        return LastSleepSummaryViewState(
            isActive: false,
            startedAt: lastSleep.startedAt,
            endedAt: lastSleep.endedAt
        )
    }
}
