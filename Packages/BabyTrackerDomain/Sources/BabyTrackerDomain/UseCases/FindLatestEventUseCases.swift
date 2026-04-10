import Foundation

public enum FindLatestEventUseCases {
    public static func latestEvent(from events: [BabyEvent]) -> BabyEvent? {
        events.max { left, right in
            left.metadata.occurredAt < right.metadata.occurredAt
        }
    }

    public static func latestNappy(from events: [BabyEvent]) -> NappyEvent? {
        events.compactMap { event -> NappyEvent? in
            guard case let .nappy(nappyEvent) = event else {
                return nil
            }

            return nappyEvent
        }.max { left, right in
            left.metadata.occurredAt < right.metadata.occurredAt
        }
    }

    public static func latestSleepSummary(
        from events: [BabyEvent],
        activeSleep: SleepEvent? = nil
    ) -> LatestSleepSummary? {
        if let activeSleep {
            return LatestSleepSummary(
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

        return LatestSleepSummary(
            isActive: false,
            startedAt: lastSleep.startedAt,
            endedAt: lastSleep.endedAt
        )
    }
}

public struct LatestSleepSummary: Equatable, Sendable {
    public let isActive: Bool
    public let startedAt: Date
    public let endedAt: Date?

    public init(isActive: Bool, startedAt: Date, endedAt: Date?) {
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
