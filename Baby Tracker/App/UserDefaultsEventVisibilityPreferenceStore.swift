import BabyTrackerDomain
import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsEventVisibilityPreferenceStore: EventVisibilityPreferenceStore {
    private enum DefaultsKey {
        static let enabledKinds = "eventVisibility.enabledKinds"
        static let foodMigrationCompleted = "eventVisibility.foodMigrationCompleted"
    }

    private let userDefaults: UserDefaults

    var enabledEventKinds: Set<BabyEventKind> {
        guard let rawValues = userDefaults.array(forKey: DefaultsKey.enabledKinds) as? [String] else {
            return Set(BabyEventKind.allCases)
        }

        var kinds = Set(rawValues.compactMap(BabyEventKind.init(rawValue:)))
        if !userDefaults.bool(forKey: DefaultsKey.foodMigrationCompleted) {
            kinds.insert(.food)
            setEnabledEventKinds(kinds)
            userDefaults.set(true, forKey: DefaultsKey.foodMigrationCompleted)
        }
        return kinds
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if userDefaults.object(forKey: DefaultsKey.enabledKinds) == nil {
            userDefaults.set(true, forKey: DefaultsKey.foodMigrationCompleted)
        }
    }

    func setEnabledEventKinds(_ kinds: Set<BabyEventKind>) {
        let rawValues = kinds.map { $0.rawValue }
        userDefaults.set(rawValues, forKey: DefaultsKey.enabledKinds)
    }
}
