import Foundation

@MainActor
public final class UserDefaultsChildSelectionStore: ChildSelectionStore {
    private enum DefaultsKey {
        static let selectedChildID = "stage1.selectedChildID"
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func loadSelectedChildID() -> UUID? {
        guard let rawValue = userDefaults.string(forKey: DefaultsKey.selectedChildID) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    public func saveSelectedChildID(_ childID: UUID?) {
        userDefaults.set(childID?.uuidString, forKey: DefaultsKey.selectedChildID)
    }
}
