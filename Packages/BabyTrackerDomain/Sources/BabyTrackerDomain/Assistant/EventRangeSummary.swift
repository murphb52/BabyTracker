import Foundation

/// Totals for one category of events over a period. Fields that don't apply
/// to the category stay at zero, which keeps the type simple to build and read.
public struct EventRangeSummary: Equatable, Sendable {
    public let category: EventSummaryCategory
    public let period: RelativePeriod
    public let eventCount: Int

    public let bottleFeedCount: Int
    public let bottleTotalMilliliters: Int
    public let breastFeedCount: Int
    public let breastFeedTotalMinutes: Int

    /// Only completed sleeps are counted, matching the Summary tab.
    public let completedSleepCount: Int
    public let totalSleepMinutes: Int
    public let longestSleepMinutes: Int?

    public let nappyCountsByType: [NappyType: Int]

    /// Food or medicine names with how many times each was logged.
    public let itemCountsByName: [String: Int]

    public init(
        category: EventSummaryCategory,
        period: RelativePeriod,
        eventCount: Int,
        bottleFeedCount: Int = 0,
        bottleTotalMilliliters: Int = 0,
        breastFeedCount: Int = 0,
        breastFeedTotalMinutes: Int = 0,
        completedSleepCount: Int = 0,
        totalSleepMinutes: Int = 0,
        longestSleepMinutes: Int? = nil,
        nappyCountsByType: [NappyType: Int] = [:],
        itemCountsByName: [String: Int] = [:]
    ) {
        self.category = category
        self.period = period
        self.eventCount = eventCount
        self.bottleFeedCount = bottleFeedCount
        self.bottleTotalMilliliters = bottleTotalMilliliters
        self.breastFeedCount = breastFeedCount
        self.breastFeedTotalMinutes = breastFeedTotalMinutes
        self.completedSleepCount = completedSleepCount
        self.totalSleepMinutes = totalSleepMinutes
        self.longestSleepMinutes = longestSleepMinutes
        self.nappyCountsByType = nappyCountsByType
        self.itemCountsByName = itemCountsByName
    }

    public var averageEventsPerDay: Double {
        Double(eventCount) / Double(period.dayCount)
    }

    public var averageSleepMinutesPerDay: Double {
        Double(totalSleepMinutes) / Double(period.dayCount)
    }

    public var averageBottleMillilitersPerDay: Double {
        Double(bottleTotalMilliliters) / Double(period.dayCount)
    }
}
