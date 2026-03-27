import Foundation

public enum FeedVolumeConverter {
    private static let millilitersPerOunce = 29.5735

    public static func milliliters(from ounces: Double) -> Int {
        Int((ounces * millilitersPerOunce).rounded())
    }

    public static func ounces(from milliliters: Int) -> Double {
        Double(milliliters) / millilitersPerOunce
    }

    public static func format(amountMilliliters: Int, in unit: FeedVolumeUnit) -> String {
        switch unit {
        case .milliliters:
            return "\(amountMilliliters) \(unit.shortTitle)"
        case .ounces:
            let ounces = ounces(from: amountMilliliters)
            let formatted = ounces.formatted(
                .number
                    .precision(.fractionLength(0...1))
                    .rounded(rule: .toNearestOrAwayFromZero, increment: 0.1)
            )
            return "\(formatted) \(unit.shortTitle)"
        }
    }
}
