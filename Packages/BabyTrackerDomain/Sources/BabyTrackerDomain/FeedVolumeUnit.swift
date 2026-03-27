import Foundation

public enum FeedVolumeUnit: String, CaseIterable, Codable, Sendable {
    case milliliters
    case ounces

    public var title: String {
        switch self {
        case .milliliters:
            "Milliliters (mL)"
        case .ounces:
            "Ounces (oz)"
        }
    }

    public var shortTitle: String {
        switch self {
        case .milliliters:
            "mL"
        case .ounces:
            "oz"
        }
    }
}
