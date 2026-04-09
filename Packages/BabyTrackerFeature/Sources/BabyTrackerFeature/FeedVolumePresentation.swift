import BabyTrackerDomain
import Foundation

enum FeedVolumePresentation {
    static func amountText(
        for amountMilliliters: Int,
        unit: FeedVolumeUnit
    ) -> String {
        FeedVolumeConverter.format(amountMilliliters: amountMilliliters, in: unit)
    }

    static func perDayText(
        for amountMilliliters: Int,
        unit: FeedVolumeUnit
    ) -> String {
        "\(amountText(for: amountMilliliters, unit: unit))/day"
    }
}
