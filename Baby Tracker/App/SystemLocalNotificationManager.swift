import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import UIKit
import UserNotifications

@MainActor
final class SystemLocalNotificationManager: NSObject, LocalNotificationManaging {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        super.init()
        self.notificationCenter.delegate = self
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return
        case .notDetermined:
            break
        default:
            return
        }

        let isAuthorized = (try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])) == true
        guard isAuthorized else {
            return
        }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {
        guard await isAuthorized() else { return }

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

    func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {
        guard await isAuthorized() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Still sleeping?"
        content.body = "\(childName) has been asleep longer than usual. Tap to check."
        content.sound = .default
        content.userInfo = ["childID": childID.uuidString, "childName": childName, "kind": "sleep"]

        let id = sleepDriftIdentifier(childID: childID)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fireAfter), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        try? await notificationCenter.add(request)
    }

    func cancelSleepDriftNotification(childID: UUID) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [sleepDriftIdentifier(childID: childID)])
    }

    func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {
        guard await isAuthorized() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Anything to log for \(childName)?"
        content.body = "It's been a while since the last recorded event. Did you forget to log something?"
        content.sound = .default
        content.userInfo = ["childID": childID.uuidString, "childName": childName, "kind": "inactivity"]

        let id = inactivityDriftIdentifier(childID: childID)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fireAfter), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        try? await notificationCenter.add(request)
    }

    func cancelInactivityDriftNotification(childID: UUID) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [inactivityDriftIdentifier(childID: childID)])
    }

    func pendingDriftNotifications() async -> [PendingDriftNotification] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.compactMap { request -> PendingDriftNotification? in
            guard request.identifier.hasPrefix("drift."),
                  let trigger = request.trigger as? UNTimeIntervalNotificationTrigger,
                  let fireDate = trigger.nextTriggerDate(),
                  let kindRaw = request.content.userInfo["kind"] as? String,
                  let childIDString = request.content.userInfo["childID"] as? String,
                  let childID = UUID(uuidString: childIDString),
                  let childName = request.content.userInfo["childName"] as? String
            else { return nil }

            let kind: PendingDriftNotification.Kind = kindRaw == "sleep" ? .sleep : .inactivity
            return PendingDriftNotification(
                id: request.identifier,
                kind: kind,
                childID: childID,
                childName: childName,
                fireDate: fireDate
            )
        }
        .sorted { $0.fireDate < $1.fireDate }
    }

    // MARK: - Private helpers

    private func isAuthorized() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    private func sleepDriftIdentifier(childID: UUID) -> String {
        "drift.sleep.\(childID.uuidString)"
    }

    private func inactivityDriftIdentifier(childID: UUID) -> String {
        "drift.inactivity.\(childID.uuidString)"
    }
}

extension SystemLocalNotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        _ = center
        _ = notification
        return [.banner, .list, .sound]
    }
}
