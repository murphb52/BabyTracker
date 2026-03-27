import BabyTrackerDomain
import Foundation

@MainActor
public final class NoOpLocalNotificationManager: LocalNotificationManaging {
    public init() {}

    public func requestAuthorizationIfNeeded() async {}

    public func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
        _ = content
    }
}
