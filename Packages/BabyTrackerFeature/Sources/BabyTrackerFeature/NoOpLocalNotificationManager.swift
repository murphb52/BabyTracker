import BabyTrackerDomain
import Foundation

@MainActor
public final class NoOpLocalNotificationManager: LocalNotificationManaging {
    public init() {}

    public func requestAuthorizationIfNeeded() async {}

    public func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
        _ = content
    }

    public func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {}
    public func cancelSleepDriftNotification(childID: UUID) async {}
    public func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {}
    public func cancelInactivityDriftNotification(childID: UUID) async {}
    public func pendingDriftNotifications() async -> [PendingDriftNotification] { [] }
}
