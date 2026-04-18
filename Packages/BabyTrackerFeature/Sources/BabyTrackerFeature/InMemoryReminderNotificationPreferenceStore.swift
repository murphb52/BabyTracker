import Foundation

@MainActor
public final class InMemoryReminderNotificationPreferenceStore: ReminderNotificationPreferenceStore {
    public var isReminderNotificationsEnabled: Bool

    public init(isReminderNotificationsEnabled: Bool = true) {
        self.isReminderNotificationsEnabled = isReminderNotificationsEnabled
    }

    public func setReminderNotificationsEnabled(_ isEnabled: Bool) {
        isReminderNotificationsEnabled = isEnabled
    }
}
