import Foundation

public enum BabyEventError: LocalizedError, Equatable, Sendable {
    case invalidDateRange
    case invalidBottleAmount
    case activeSleepAlreadyInProgress
    case noActiveSleepInProgress
    case sleepAlreadyActive
    case activeBreastFeedAlreadyInProgress
    case noActiveBreastFeedInProgress
    case breastFeedAlreadyActive

    public var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            "End time must be later than the start time."
        case .invalidBottleAmount:
            "Bottle feeds must record a positive amount."
        case .activeSleepAlreadyInProgress:
            "A sleep session is already in progress."
        case .noActiveSleepInProgress:
            "There is no active sleep session to end."
        case .sleepAlreadyActive:
            "This sleep session is already active."
        case .activeBreastFeedAlreadyInProgress:
            "A breast feed session is already in progress."
        case .noActiveBreastFeedInProgress:
            "There is no active breast feed session to end."
        case .breastFeedAlreadyActive:
            "This breast feed session is already active."
        }
    }
}
