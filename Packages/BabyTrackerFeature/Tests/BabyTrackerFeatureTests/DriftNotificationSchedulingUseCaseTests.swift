@testable import BabyTrackerFeature
import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct DriftNotificationSchedulingUseCaseTests {
    @Test
    func sleepSchedulingUsesAdaptiveGraceWhenAlreadyOverThreshold() async throws {
        let manager = SpyLocalNotificationManager()
        let childID = UUID()
        let now = Date(timeIntervalSince1970: 20_000)
        let activeSleepStartedAt = now.addingTimeInterval(-(4 * 60 * 60))

        await ScheduleSleepDriftNotificationUseCase.execute(
            input: .init(
                childID: childID,
                childName: "Robin",
                activeSleepStartedAt: activeSleepStartedAt,
                completedSleepEvents: [],
                now: now
            ),
            notificationManager: manager
        )

        let scheduled = try #require(manager.lastSleepSchedule)
        #expect(scheduled.childID == childID)
        #expect(abs(scheduled.fireAfter - 18 * 60) < 0.1)
    }

    @Test
    func inactivitySchedulingUsesAdaptiveGraceWhenAlreadyOverThreshold() async throws {
        let manager = SpyLocalNotificationManager()
        let childID = UUID()
        let now = Date(timeIntervalSince1970: 40_000)
        let lastEventOccurredAt = now.addingTimeInterval(-(5 * 60 * 60))

        let events: [BabyEvent] = try [
            makeBottleEvent(childID: childID, occurredAt: now.addingTimeInterval(-(8 * 60 * 60))),
            makeBottleEvent(childID: childID, occurredAt: now.addingTimeInterval(-(7 * 60 * 60))),
            makeBottleEvent(childID: childID, occurredAt: lastEventOccurredAt)
        ]

        await ScheduleInactivityDriftNotificationUseCase.execute(
            input: .init(
                childID: childID,
                childName: "Robin",
                lastEventOccurredAt: lastEventOccurredAt,
                allEvents: events,
                now: now
            ),
            notificationManager: manager
        )

        let scheduled = try #require(manager.lastInactivitySchedule)
        #expect(scheduled.childID == childID)
        #expect(abs(scheduled.fireAfter - 24 * 60) < 0.1)
    }

    private func makeBottleEvent(childID: UUID, occurredAt: Date) throws -> BabyEvent {
        .bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: UUID()
            ),
            amountMilliliters: 120
        ))
    }
}

@MainActor
private final class SpyLocalNotificationManager: LocalNotificationManaging {
    struct Scheduled {
        let childID: UUID
        let fireAfter: TimeInterval
    }

    var lastSleepSchedule: Scheduled?
    var lastInactivitySchedule: Scheduled?

    func requestAuthorizationIfNeeded() async {}

    func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
        _ = content
    }

    func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {
        _ = childName
        lastSleepSchedule = Scheduled(childID: childID, fireAfter: fireAfter)
    }

    func cancelSleepDriftNotification(childID: UUID) async {
        _ = childID
    }

    func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {
        _ = childName
        lastInactivitySchedule = Scheduled(childID: childID, fireAfter: fireAfter)
    }

    func cancelInactivityDriftNotification(childID: UUID) async {
        _ = childID
    }

    func pendingDriftNotifications() async -> [PendingDriftNotification] {
        []
    }
}
