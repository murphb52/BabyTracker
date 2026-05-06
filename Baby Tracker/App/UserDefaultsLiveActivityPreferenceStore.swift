import BabyTrackerDomain
import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsLiveActivityPreferenceStore: LiveActivityPreferenceStore {
    private enum DefaultsKey {
        static let isLiveActivityEnabled = "liveActivity.isEnabled"
    }

    private static let category = "LiveActivity"

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
        let previous = userDefaults.object(forKey: DefaultsKey.isLiveActivityEnabled) as? Bool
        userDefaults.set(isEnabled, forKey: DefaultsKey.isLiveActivityEnabled)
        AppLogger.shared.log(
            .info,
            category: Self.category,
            "[preference] setLiveActivityEnabled \(previous.map(String.init) ?? "unset") → \(isEnabled)"
        )
    }
}
