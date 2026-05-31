import BabyTrackerDomain
import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsMedicationReminderPreferenceStore: MedicationReminderPreferenceStore {
    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func preference(for medicineName: String, childID: UUID) -> MedicationReminderPreference? {
        let key = defaultsKey(medicineName: medicineName, childID: childID)
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(MedicationReminderPreference.self, from: data)
    }

    func savePreference(_ preference: MedicationReminderPreference, for medicineName: String, childID: UUID) {
        let key = defaultsKey(medicineName: medicineName, childID: childID)
        guard let data = try? encoder.encode(preference) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func defaultsKey(medicineName: String, childID: UUID) -> String {
        "medicationReminder.\(childID.uuidString).\(medicineName.lowercased())"
    }
}
