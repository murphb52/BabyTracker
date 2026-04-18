import BabyTrackerDomain
import Foundation

public enum ScheduleInactivityDriftNotificationUseCase {
    public struct Input {
        public let childID: UUID
        public let childName: String
        public let lastEventOccurredAt: Date
        public let allEvents: [BabyEvent]
        public let now: Date

        public init(
            childID: UUID,
            childName: String,
            lastEventOccurredAt: Date,
            allEvents: [BabyEvent],
            now: Date = .now
        ) {
            self.childID = childID
            self.childName = childName
            self.lastEventOccurredAt = lastEventOccurredAt
            self.allEvents = allEvents
            self.now = now
        }
    }

    @MainActor
    public static func execute(input: Input, notificationManager: any LocalNotificationManaging) async {
        let threshold = CalculateInactivityDriftThresholdUseCase().execute(
            .init(events: input.allEvents)
        )

        let targetFireDate = input.lastEventOccurredAt.addingTimeInterval(threshold)
        let fireAfter = targetFireDate.timeIntervalSince(input.now)
        let resolvedFireAfter = fireAfter > 0 ? fireAfter : overdueGrace(for: threshold)

        await notificationManager.scheduleInactivityDriftNotification(
            childID: input.childID,
            childName: input.childName,
            fireAfter: resolvedFireAfter
        )
    }

    private static func overdueGrace(for threshold: TimeInterval) -> TimeInterval {
        min(max(threshold * 0.10, 5 * 60), 30 * 60)
    }
}
