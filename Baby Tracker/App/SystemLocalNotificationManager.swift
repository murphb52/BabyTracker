import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import UserNotifications

@MainActor
final class SystemLocalNotificationManager: LocalNotificationManaging {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return
        }

        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notificationContent,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }
}
