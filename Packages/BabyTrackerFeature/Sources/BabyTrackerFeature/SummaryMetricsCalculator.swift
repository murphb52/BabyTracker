import BabyTrackerDomain
import Foundation

public enum SummaryTimeRange: String, CaseIterable, Identifiable, Sendable {
    case today
    case sevenDays
    case thirtyDays
    case allTime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today:
            "Today"
        case .sevenDays:
            "7 Days"
        case .thirtyDays:
            "30 Days"
        case .allTime:
            "All Time"
        }
    }
}

public struct SummaryDayCount: Equatable, Sendable {
    public let date: Date
    public let label: String
    public let count: Int

    public init(date: Date, label: String, count: Int) {
        self.date = date
        self.label = label
        self.count = count
    }
}

public struct SummaryHourCount: Equatable, Sendable {
    public let hour: Int
    public let label: String
    public let count: Int

    public init(hour: Int, label: String, count: Int) {
        self.hour = hour
        self.label = label
        self.count = count
    }
}

public struct SummarySnapshot: Equatable, Sendable {
    public let eventCount: Int
    public let totalFeeds: Int
    public let totalNappies: Int
    public let totalSleepMinutes: Int
    public let averageFeedDurationMinutes: Int?
    public let loggingStreakDays: Int
    public let averageFeedIntervalMinutes: Int?
    public let averageSleepBlockMinutes: Int?
    public let shortestSleepBlockMinutes: Int?
    public let longestSleepBlockMinutes: Int?
    public let wetNappyCount: Int
    public let dirtyNappyCount: Int
    public let mixedNappyCount: Int
    public let dryNappyCount: Int
    public let dailyEventCounts: [SummaryDayCount]
    public let feedCountsByHour: [SummaryHourCount]

    public init(
        eventCount: Int,
        totalFeeds: Int,
        totalNappies: Int,
        totalSleepMinutes: Int,
        averageFeedDurationMinutes: Int?,
        loggingStreakDays: Int,
        averageFeedIntervalMinutes: Int?,
        averageSleepBlockMinutes: Int?,
        shortestSleepBlockMinutes: Int?,
        longestSleepBlockMinutes: Int?,
        wetNappyCount: Int,
        dirtyNappyCount: Int,
        mixedNappyCount: Int,
        dryNappyCount: Int,
        dailyEventCounts: [SummaryDayCount],
        feedCountsByHour: [SummaryHourCount]
    ) {
        self.eventCount = eventCount
        self.totalFeeds = totalFeeds
        self.totalNappies = totalNappies
        self.totalSleepMinutes = totalSleepMinutes
        self.averageFeedDurationMinutes = averageFeedDurationMinutes
        self.loggingStreakDays = loggingStreakDays
        self.averageFeedIntervalMinutes = averageFeedIntervalMinutes
        self.averageSleepBlockMinutes = averageSleepBlockMinutes
        self.shortestSleepBlockMinutes = shortestSleepBlockMinutes
        self.longestSleepBlockMinutes = longestSleepBlockMinutes
        self.wetNappyCount = wetNappyCount
        self.dirtyNappyCount = dirtyNappyCount
        self.mixedNappyCount = mixedNappyCount
        self.dryNappyCount = dryNappyCount
        self.dailyEventCounts = dailyEventCounts
        self.feedCountsByHour = feedCountsByHour
    }
}

public enum SummaryMetricsCalculator {
    public static func makeSnapshot(
        from events: [BabyEvent],
        range: SummaryTimeRange,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> SummarySnapshot {
        let sortedEvents = events.sorted { $0.metadata.occurredAt < $1.metadata.occurredAt }
        let rangeEvents = filter(events: sortedEvents, range: range, now: now, calendar: calendar)

        let feedEvents = rangeEvents.compactMap { event -> BabyEvent? in
            switch event {
            case .breastFeed, .bottleFeed:
                event
            case .sleep, .nappy:
                nil
            }
        }

        let nappyEvents = rangeEvents.compactMap { event -> NappyEvent? in
            guard case let .nappy(nappy) = event else { return nil }
            return nappy
        }

        let completedSleepEvents = rangeEvents.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleep) = event, sleep.endedAt != nil else { return nil }
            return sleep
        }

        let feedDurations = feedEvents.compactMap { feedDurationMinutes(for: $0) }
        let sleepDurations = completedSleepEvents.compactMap { sleepDurationMinutes(for: $0) }
        let averageFeedDuration = average(of: feedDurations)
        let averageSleepDuration = average(of: sleepDurations)
        let shortestSleep = sleepDurations.min()
        let longestSleep = sleepDurations.max()

        let dailyCounts = makeDailyCounts(events: rangeEvents, now: now, calendar: calendar)
        let hourlyFeedCounts = makeHourlyFeedCounts(events: feedEvents, now: now, calendar: calendar)

        return SummarySnapshot(
            eventCount: rangeEvents.count,
            totalFeeds: feedEvents.count,
            totalNappies: nappyEvents.count,
            totalSleepMinutes: sleepDurations.reduce(0, +),
            averageFeedDurationMinutes: averageFeedDuration,
            loggingStreakDays: makeLoggingStreakDays(from: sortedEvents, now: now, calendar: calendar),
            averageFeedIntervalMinutes: averageFeedIntervalMinutes(for: feedEvents),
            averageSleepBlockMinutes: averageSleepDuration,
            shortestSleepBlockMinutes: shortestSleep,
            longestSleepBlockMinutes: longestSleep,
            wetNappyCount: nappyEvents.filter { $0.type == .wee }.count,
            dirtyNappyCount: nappyEvents.filter { $0.type == .poo }.count,
            mixedNappyCount: nappyEvents.filter { $0.type == .mixed }.count,
            dryNappyCount: nappyEvents.filter { $0.type == .dry }.count,
            dailyEventCounts: dailyCounts,
            feedCountsByHour: hourlyFeedCounts
        )
    }

    private static func filter(
        events: [BabyEvent],
        range: SummaryTimeRange,
        now: Date,
        calendar: Calendar
    ) -> [BabyEvent] {
        switch range {
        case .allTime:
            events
        case .today:
            events.filter { calendar.isDate($0.metadata.occurredAt, inSameDayAs: now) }
        case .sevenDays:
            events.filter { isWithinDays($0.metadata.occurredAt, days: 7, now: now, calendar: calendar) }
        case .thirtyDays:
            events.filter { isWithinDays($0.metadata.occurredAt, days: 30, now: now, calendar: calendar) }
        }
    }

    private static func isWithinDays(
        _ date: Date,
        days: Int,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now)) else {
            return false
        }

        return date >= start && date <= now
    }

    private static func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else {
            return nil
        }

        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    private static func feedDurationMinutes(for event: BabyEvent) -> Int? {
        switch event {
        case let .breastFeed(feed):
            return max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
        case .bottleFeed:
            return nil
        case .sleep, .nappy:
            return nil
        }
    }

    private static func sleepDurationMinutes(for event: SleepEvent) -> Int? {
        guard let endedAt = event.endedAt else {
            return nil
        }

        return max(1, Int(endedAt.timeIntervalSince(event.startedAt) / 60))
    }

    private static func averageFeedIntervalMinutes(for feedEvents: [BabyEvent]) -> Int? {
        let sortedTimes = feedEvents.map(\.metadata.occurredAt).sorted()
        guard sortedTimes.count > 1 else {
            return nil
        }

        var intervals: [Int] = []

        for index in 1..<sortedTimes.count {
            let interval = sortedTimes[index].timeIntervalSince(sortedTimes[index - 1])
            intervals.append(max(1, Int(interval / 60)))
        }

        return average(of: intervals)
    }

    private static func makeLoggingStreakDays(
        from events: [BabyEvent],
        now: Date,
        calendar: Calendar
    ) -> Int {
        let daySet = Set(events.map { calendar.startOfDay(for: $0.metadata.occurredAt) })
        guard !daySet.isEmpty else {
            return 0
        }

        var streak = 0
        var currentDay = calendar.startOfDay(for: now)

        while daySet.contains(currentDay) {
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }

            currentDay = previousDay
        }

        return streak
    }

    private static func makeDailyCounts(
        events: [BabyEvent],
        now: Date,
        calendar: Calendar
    ) -> [SummaryDayCount] {
        var countsByDay: [Date: Int] = [:]

        for event in events {
            let day = calendar.startOfDay(for: event.metadata.occurredAt)
            countsByDay[day, default: 0] += 1
        }

        var result: [SummaryDayCount] = []

        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else {
                continue
            }

            result.append(
                SummaryDayCount(
                    date: day,
                    label: day.formatted(.dateTime.weekday(.narrow)),
                    count: countsByDay[day, default: 0]
                )
            )
        }

        return result
    }

    private static func makeHourlyFeedCounts(
        events: [BabyEvent],
        now: Date,
        calendar: Calendar
    ) -> [SummaryHourCount] {
        var countsByHour: [Int: Int] = [:]

        for event in events {
            let hour = calendar.component(.hour, from: event.metadata.occurredAt)
            countsByHour[hour, default: 0] += 1
        }

        let representativeHours = [0, 4, 8, 12, 16, 20]

        return representativeHours.map { hour in
            let labelDate = calendar.date(
                bySettingHour: hour,
                minute: 0,
                second: 0,
                of: now
            ) ?? now

            return SummaryHourCount(
                hour: hour,
                label: labelDate.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))),
                count: countsByHour[hour, default: 0]
            )
        }
    }
}
