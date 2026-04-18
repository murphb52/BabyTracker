import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsReminderNotificationPreferenceStore: ReminderNotificationPreferenceStore {
    private enum DefaultsKey {
        static let isReminderNotificationsEnabled = "reminderNotifications.isEnabled"
    }

    private let userDefaults: UserDefaults

    var isReminderNotificationsEnabled: Bool {
        if userDefaults.object(forKey: DefaultsKey.isReminderNotificationsEnabled) == nil {
            return true
        }

        return userDefaults.bool(forKey: DefaultsKey.isReminderNotificationsEnabled)
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func setReminderNotificationsEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: DefaultsKey.isReminderNotificationsEnabled)
    }
}
