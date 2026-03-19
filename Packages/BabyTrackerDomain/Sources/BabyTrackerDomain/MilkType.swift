import Foundation

public enum MilkType: String, CaseIterable, Codable, Sendable {
    case breastMilk
    case formula
    case mixed
    case other
}
