import Foundation

@MainActor
public protocol ReminderNotificationPreferenceStore: AnyObject {
    var isReminderNotificationsEnabled: Bool { get }
    func setReminderNotificationsEnabled(_ isEnabled: Bool)
}
