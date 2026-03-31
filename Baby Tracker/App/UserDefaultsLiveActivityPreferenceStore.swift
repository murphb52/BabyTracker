import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsLiveActivityPreferenceStore: LiveActivityPreferenceStore {
    private enum DefaultsKey {
        static let isLiveActivityEnabled = "liveActivity.isEnabled"
    }

    private let userDefaults: UserDefaults

    var isLiveActivityEnabled: Bool {
        if userDefaults.object(forKey: DefaultsKey.isLiveActivityEnabled) == nil {
            return true
        }

        return userDefaults.bool(forKey: DefaultsKey.isLiveActivityEnabled)
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func setLiveActivityEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: DefaultsKey.isLiveActivityEnabled)
    }
}
