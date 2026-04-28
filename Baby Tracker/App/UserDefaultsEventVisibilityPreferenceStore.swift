import BabyTrackerDomain
import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsEventVisibilityPreferenceStore: EventVisibilityPreferenceStore {
    private enum DefaultsKey {
        static let enabledKinds = "eventVisibility.enabledKinds"
    }

    private let userDefaults: UserDefaults

    var enabledEventKinds: Set<BabyEventKind> {
        guard let rawValues = userDefaults.array(forKey: DefaultsKey.enabledKinds) as? [String] else {
            return Set(BabyEventKind.allCases)
        }

        let kinds = rawValues.compactMap(BabyEventKind.init(rawValue:))
        return Set(kinds)
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func setEnabledEventKinds(_ kinds: Set<BabyEventKind>) {
        let rawValues = kinds.map { $0.rawValue }
        userDefaults.set(rawValues, forKey: DefaultsKey.enabledKinds)
    }
}
