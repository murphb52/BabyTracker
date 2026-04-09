import Foundation

public struct TodaySummary: Equatable, Sendable {
    public let bottleTotalMilliliters: Int
    public let bottleCount: Int
    public let formulaMilliliters: Int
    public let breastMilkMilliliters: Int
    public let mixedMilkMilliliters: Int

    public let breastFeedTotalMinutes: Int
    public let breastFeedCount: Int
    public let averageBreastFeedMinutes: Int?
    public let averageFeedIntervalMinutes: Int?

    public let minutesSinceLastFeed: Int?

    public let totalSleepMinutes: Int
    public let daytimeSleepMinutes: Int
    public let nighttimeSleepMinutes: Int
    public let longestSleepBlockMinutes: Int?

    public let totalNappies: Int
    public let wetNappyCount: Int
    public let dirtyNappyCount: Int
    public let mixedNappyCount: Int
    public let wetInclusiveCount: Int
    public let dirtyInclusiveCount: Int

    public let loggingStreakDays: Int

    public init(
        bottleTotalMilliliters: Int,
        bottleCount: Int,
        formulaMilliliters: Int,
        breastMilkMilliliters: Int,
        mixedMilkMilliliters: Int,
        breastFeedTotalMinutes: Int,
        breastFeedCount: Int,
        averageBreastFeedMinutes: Int?,
        averageFeedIntervalMinutes: Int?,
        minutesSinceLastFeed: Int?,
        totalSleepMinutes: Int,
        daytimeSleepMinutes: Int,
        nighttimeSleepMinutes: Int,
        longestSleepBlockMinutes: Int?,
        totalNappies: Int,
        wetNappyCount: Int,
        dirtyNappyCount: Int,
        mixedNappyCount: Int,
        wetInclusiveCount: Int,
        dirtyInclusiveCount: Int,
        loggingStreakDays: Int
    ) {
        self.bottleTotalMilliliters = bottleTotalMilliliters
        self.bottleCount = bottleCount
        self.formulaMilliliters = formulaMilliliters
        self.breastMilkMilliliters = breastMilkMilliliters
        self.mixedMilkMilliliters = mixedMilkMilliliters
        self.breastFeedTotalMinutes = breastFeedTotalMinutes
        self.breastFeedCount = breastFeedCount
        self.averageBreastFeedMinutes = averageBreastFeedMinutes
        self.averageFeedIntervalMinutes = averageFeedIntervalMinutes
        self.minutesSinceLastFeed = minutesSinceLastFeed
        self.totalSleepMinutes = totalSleepMinutes
        self.daytimeSleepMinutes = daytimeSleepMinutes
        self.nighttimeSleepMinutes = nighttimeSleepMinutes
        self.longestSleepBlockMinutes = longestSleepBlockMinutes
        self.totalNappies = totalNappies
        self.wetNappyCount = wetNappyCount
        self.dirtyNappyCount = dirtyNappyCount
        self.mixedNappyCount = mixedNappyCount
        self.wetInclusiveCount = wetInclusiveCount
        self.dirtyInclusiveCount = dirtyInclusiveCount
        self.loggingStreakDays = loggingStreakDays
    }
}
