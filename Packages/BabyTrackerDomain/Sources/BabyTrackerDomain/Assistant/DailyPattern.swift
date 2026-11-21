import Foundation

/// How often a category of event started in each hour of the day over a period.
public struct DailyPattern: Equatable, Sendable {
    public let category: EventSummaryCategory
    public let period: RelativePeriod
    /// Always 24 entries, index 0 = midnight to 1am.
    public let countsByHour: [Int]

    public init(category: EventSummaryCategory, period: RelativePeriod, countsByHour: [Int]) {
        precondition(countsByHour.count == 24, "DailyPattern needs one count per hour")
        self.category = category
        self.period = period
        self.countsByHour = countsByHour
    }

    public var eventCount: Int {
        countsByHour.reduce(0, +)
    }

    /// The hours with the most events, busiest first, ignoring empty hours.
    /// Ties keep the earlier hour first so the result is stable.
    public func busiestHours(limit: Int) -> [Int] {
        countsByHour.indices
            .filter { countsByHour[$0] > 0 }
            .sorted { left, right in
                countsByHour[left] == countsByHour[right] ? left < right : countsByHour[left] > countsByHour[right]
            }
            .prefix(limit)
            .map { $0 }
    }
}
