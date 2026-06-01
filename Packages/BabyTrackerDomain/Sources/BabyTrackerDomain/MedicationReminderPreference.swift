import Foundation

public enum ReminderMode: String, Codable, Equatable, Sendable, CaseIterable {
    case safeToGive
    case nextDueDose
}

public enum ReminderReferencePoint: String, Codable, Equatable, Sendable, CaseIterable {
    case doseTime
    case now
}

public struct MedicationReminderPreference: Codable, Equatable, Sendable {
    public var intervalHours: Int
    public var mode: ReminderMode
    public var referencePoint: ReminderReferencePoint

    public init(intervalHours: Int, mode: ReminderMode, referencePoint: ReminderReferencePoint) {
        self.intervalHours = intervalHours
        self.mode = mode
        self.referencePoint = referencePoint
    }
}
