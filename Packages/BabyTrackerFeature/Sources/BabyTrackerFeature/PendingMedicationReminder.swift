import Foundation

public struct PendingMedicationReminder: Equatable, Sendable {
    public let id: String
    public let childID: UUID
    public let medicineName: String
    public let fireDate: Date

    public init(id: String, childID: UUID, medicineName: String, fireDate: Date) {
        self.id = id
        self.childID = childID
        self.medicineName = medicineName
        self.fireDate = fireDate
    }
}
