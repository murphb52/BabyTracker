import Foundation

public enum BabyEventError: LocalizedError, Equatable, Sendable {
    case invalidDateRange
    case invalidBottleAmount
    case invalidMedicationAmount
    case invalidMedicationName
    case activeSleepAlreadyInProgress
    case noActiveSleepInProgress
    case sleepAlreadyActive

    public var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            "End time must be later than the start time."
        case .invalidBottleAmount:
            "Bottle feeds must record a positive amount."
        case .invalidMedicationAmount:
            "Medication doses must record a positive amount."
        case .invalidMedicationName:
            "Medication must have a name."
        case .activeSleepAlreadyInProgress:
            "A sleep session is already in progress."
        case .noActiveSleepInProgress:
            "There is no active sleep session to end."
        case .sleepAlreadyActive:
            "This sleep session is already active."
        }
    }
}
