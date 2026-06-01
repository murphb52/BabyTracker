import BabyTrackerDomain
import Foundation

@MainActor
public final class NoOpLocalNotificationManager: LocalNotificationManaging {
    public init() {}

    public func isAuthorizedForNotifications() async -> Bool { true }
    public func requestAuthorizationIfNeeded() async -> Bool { true }

    public func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
        _ = content
    }

    public func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {}
    public func cancelSleepDriftNotification(childID: UUID) async {}
    public func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {}
    public func cancelInactivityDriftNotification(childID: UUID) async {}
    public func pendingDriftNotifications() async -> [PendingDriftNotification] { [] }
    public func scheduleMedicationReminderNotification(childID: UUID, childName: String, medicineName: String, mode: ReminderMode, intervalHours: Int, fireAt: Date) async {}
    public func cancelMedicationReminderNotification(childID: UUID, medicineName: String) async {}
    public func pendingMedicationReminderNotifications() async -> [PendingMedicationReminder] { [] }
}
