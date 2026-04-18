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
        // If already past threshold (e.g. app relaunched hours later), give a short grace
        // period rather than firing immediately on launch.
        let resolvedFireAfter = fireAfter > 0 ? fireAfter : 5 * 60

        await notificationManager.scheduleInactivityDriftNotification(
            childID: input.childID,
            childName: input.childName,
            fireAfter: resolvedFireAfter
        )
    }
}
