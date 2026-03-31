import Foundation

public struct AdvancedSummaryViewState: Equatable, Sendable {
    public let eventCount: Int
    public let totalFeeds: Int
    public let breastFeedCount: Int
    public let bottleFeedCount: Int
    public let averageBottleVolumeMilliliters: Int?
    public let totalSleepMinutes: Int
    public let completedSleepCount: Int
    public let averageSleepBlockMinutes: Int?
    public let longestSleepBlockMinutes: Int?
    public let totalNappies: Int
    public let wetNappyCount: Int
    public let dirtyNappyCount: Int
    public let mixedNappyCount: Int
    public let dryNappyCount: Int
    public let busiestHourLabel: String?
    public let busiestHourCount: Int
    public let dailyActivityCounts: [SummaryDayCount]
    public let hourlyActivityCounts: [SummaryHourCount]

    public init(
        eventCount: Int,
        totalFeeds: Int,
        breastFeedCount: Int,
        bottleFeedCount: Int,
        averageBottleVolumeMilliliters: Int?,
        totalSleepMinutes: Int,
        completedSleepCount: Int,
        averageSleepBlockMinutes: Int?,
        longestSleepBlockMinutes: Int?,
        totalNappies: Int,
        wetNappyCount: Int,
        dirtyNappyCount: Int,
        mixedNappyCount: Int,
        dryNappyCount: Int,
        busiestHourLabel: String?,
        busiestHourCount: Int,
        dailyActivityCounts: [SummaryDayCount],
        hourlyActivityCounts: [SummaryHourCount]
    ) {
        self.eventCount = eventCount
        self.totalFeeds = totalFeeds
        self.breastFeedCount = breastFeedCount
        self.bottleFeedCount = bottleFeedCount
        self.averageBottleVolumeMilliliters = averageBottleVolumeMilliliters
        self.totalSleepMinutes = totalSleepMinutes
        self.completedSleepCount = completedSleepCount
        self.averageSleepBlockMinutes = averageSleepBlockMinutes
        self.longestSleepBlockMinutes = longestSleepBlockMinutes
        self.totalNappies = totalNappies
        self.wetNappyCount = wetNappyCount
        self.dirtyNappyCount = dirtyNappyCount
        self.mixedNappyCount = mixedNappyCount
        self.dryNappyCount = dryNappyCount
        self.busiestHourLabel = busiestHourLabel
        self.busiestHourCount = busiestHourCount
        self.dailyActivityCounts = dailyActivityCounts
        self.hourlyActivityCounts = hourlyActivityCounts
    }
}
