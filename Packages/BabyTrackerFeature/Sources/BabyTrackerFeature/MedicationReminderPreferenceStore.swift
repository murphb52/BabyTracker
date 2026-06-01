import BabyTrackerDomain
import Foundation

@MainActor
public protocol MedicationReminderPreferenceStore: AnyObject {
    func preference(for medicineName: String, childID: UUID) -> MedicationReminderPreference?
    func savePreference(_ preference: MedicationReminderPreference, for medicineName: String, childID: UUID)
}

@MainActor
public final class InMemoryMedicationReminderPreferenceStore: MedicationReminderPreferenceStore {
    public init() {}
    public func preference(for medicineName: String, childID: UUID) -> MedicationReminderPreference? { nil }
    public func savePreference(_ preference: MedicationReminderPreference, for medicineName: String, childID: UUID) {}
}
