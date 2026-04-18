import BabyTrackerDomain
import Foundation

public enum ScheduleSleepDriftNotificationUseCase {
    public struct Input {
        public let childID: UUID
        public let childName: String
        public let activeSleepStartedAt: Date
        /// Recent completed sleeps, most recent first.
        public let completedSleepEvents: [SleepEvent]
        public let now: Date

        public init(
            childID: UUID,
            childName: String,
            activeSleepStartedAt: Date,
            completedSleepEvents: [SleepEvent],
            now: Date = .now
        ) {
            self.childID = childID
            self.childName = childName
            self.activeSleepStartedAt = activeSleepStartedAt
            self.completedSleepEvents = completedSleepEvents
            self.now = now
        }
    }

    @MainActor
    public static func execute(input: Input, notificationManager: any LocalNotificationManaging) async {
        let threshold = CalculateSleepDriftThresholdUseCase().execute(
            .init(
                completedSleepEvents: input.completedSleepEvents,
                activeSleepStartedAt: input.activeSleepStartedAt
            )
        )

        let elapsed = input.now.timeIntervalSince(input.activeSleepStartedAt)
        let remaining = threshold - elapsed
        let fireAfter = remaining > 0 ? remaining : overdueGrace(for: threshold)

        await notificationManager.scheduleSleepDriftNotification(
            childID: input.childID,
            childName: input.childName,
            fireAfter: fireAfter
        )
    }

    private static func overdueGrace(for threshold: TimeInterval) -> TimeInterval {
        min(max(threshold * 0.10, 5 * 60), 30 * 60)
    }
}
