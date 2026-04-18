import BabyTrackerDomain
import Foundation

@MainActor
public protocol LocalNotificationManaging: AnyObject {
    func requestAuthorizationIfNeeded() async
    func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async
    func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async
    func cancelSleepDriftNotification(childID: UUID) async
    func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async
    func cancelInactivityDriftNotification(childID: UUID) async
}
