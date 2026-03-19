import Foundation

public enum BabyEventError: LocalizedError, Equatable, Sendable {
    case invalidDateRange
    case invalidBottleAmount

    public var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            "End time must be later than the start time."
        case .invalidBottleAmount:
            "Bottle feeds must record a positive amount."
        }
    }
}
