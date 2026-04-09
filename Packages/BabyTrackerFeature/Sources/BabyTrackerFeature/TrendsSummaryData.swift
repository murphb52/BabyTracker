import Foundation

public enum TrendsTimeRange: String, CaseIterable, Identifiable, Sendable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case allTime = "All Time"

    public var id: String { rawValue }
}

public struct DailyBottleData: Equatable, Sendable {
    public let date: Date
    public let label: String
    public let totalMilliliters: Int
    public let formulaMilliliters: Int
    public let breastMilkMilliliters: Int
    public let mixedMilliliters: Int
    public let count: Int

    public init(
        date: Date,
        label: String,
        totalMilliliters: Int,
        formulaMilliliters: Int,
        breastMilkMilliliters: Int,
        mixedMilliliters: Int,
        count: Int
    ) {
        self.date = date
        self.label = label
        self.totalMilliliters = totalMilliliters
        self.formulaMilliliters = formulaMilliliters
        self.breastMilkMilliliters = breastMilkMilliliters
        self.mixedMilliliters = mixedMilliliters
        self.count = count
    }
}

public struct DailyBreastFeedData: Equatable, Sendable {
    public let date: Date
    public let label: String
    public let sessionCount: Int
    public let totalMinutes: Int

    public init(date: Date, label: String, sessionCount: Int, totalMinutes: Int) {
        self.date = date
        self.label = label
        self.sessionCount = sessionCount
        self.totalMinutes = totalMinutes
    }
}

public struct DailySleepData: Equatable, Sendable {
    public let date: Date
    public let label: String
    public let totalMinutes: Int

    public init(date: Date, label: String, totalMinutes: Int) {
        self.date = date
        self.label = label
        self.totalMinutes = totalMinutes
    }
}

public struct DailyNappyData: Equatable, Sendable {
    public let date: Date
    public let label: String
    public let wetCount: Int   // wee only
    public let dirtyCount: Int // poo only
    public let mixedCount: Int
    public let dryCount: Int
    public var totalCount: Int { wetCount + dirtyCount + mixedCount + dryCount }

    public init(date: Date, label: String, wetCount: Int, dirtyCount: Int, mixedCount: Int, dryCount: Int) {
        self.date = date
        self.label = label
        self.wetCount = wetCount
        self.dirtyCount = dirtyCount
        self.mixedCount = mixedCount
        self.dryCount = dryCount
    }
}

public struct TrendsSummaryData: Equatable, Sendable {
    public let dailyBottle: [DailyBottleData]
    public let dailyBreastFeed: [DailyBreastFeedData]
    public let dailySleep: [DailySleepData]
    public let dailyNappy: [DailyNappyData]
    public let avgDailyBottleMilliliters: Int?
    public let avgDailyBreastFeedSessions: Int?
    public let avgDailySleepMinutes: Int?
    public let avgDailyNappies: Int?

    public init(
        dailyBottle: [DailyBottleData],
        dailyBreastFeed: [DailyBreastFeedData],
        dailySleep: [DailySleepData],
        dailyNappy: [DailyNappyData],
        avgDailyBottleMilliliters: Int?,
        avgDailyBreastFeedSessions: Int?,
        avgDailySleepMinutes: Int?,
        avgDailyNappies: Int?
    ) {
        self.dailyBottle = dailyBottle
        self.dailyBreastFeed = dailyBreastFeed
        self.dailySleep = dailySleep
        self.dailyNappy = dailyNappy
        self.avgDailyBottleMilliliters = avgDailyBottleMilliliters
        self.avgDailyBreastFeedSessions = avgDailyBreastFeedSessions
        self.avgDailySleepMinutes = avgDailySleepMinutes
        self.avgDailyNappies = avgDailyNappies
    }
}
