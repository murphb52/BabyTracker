import BabyTrackerDomain
import Foundation

@MainActor
public protocol LocalNotificationManaging: AnyObject {
    func requestAuthorizationIfNeeded() async
    func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async
}
