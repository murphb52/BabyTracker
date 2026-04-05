import BabyTrackerDomain
import Foundation

public enum TrendsSummaryCalculator {
    public static func makeData(
        from events: [BabyEvent],
        range: TrendsTimeRange,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TrendsSummaryData {
        let sortedEvents = events.sorted { $0.metadata.occurredAt < $1.metadata.occurredAt }
        let rangeEvents = filter(events: sortedEvents, range: range, now: now, calendar: calendar)
        let dates = makeDates(range: range, events: rangeEvents, now: now, calendar: calendar)

        // Group events by day
        let eventsByDay = Dictionary(
            grouping: rangeEvents,
            by: { calendar.startOfDay(for: $0.metadata.occurredAt) }
        )

        let formatter = makeDayFormatter(calendar: calendar, totalDays: dates.count)

        let dailyBottle = dates.map { date -> DailyBottleData in
            let dayEvents = eventsByDay[date] ?? []
            let bottles = dayEvents.compactMap { event -> BottleFeedEvent? in
                guard case let .bottleFeed(feed) = event else { return nil }
                return feed
            }
            return DailyBottleData(
                date: date,
                label: formatter(date),
                totalMilliliters: bottles.reduce(0) { $0 + $1.amountMilliliters },
                count: bottles.count
            )
        }

        let dailyBreastFeed = dates.map { date -> DailyBreastFeedData in
            let dayEvents = eventsByDay[date] ?? []
            let feeds = dayEvents.compactMap { event -> BreastFeedEvent? in
                guard case let .breastFeed(feed) = event else { return nil }
                return feed
            }
            let totalMinutes = feeds.reduce(0) { total, feed in
                total + max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
            }
            return DailyBreastFeedData(
                date: date,
                label: formatter(date),
                sessionCount: feeds.count,
                totalMinutes: totalMinutes
            )
        }

        let dailySleep = dates.map { date -> DailySleepData in
            let dayEvents = eventsByDay[date] ?? []
            let sleepMinutes = dayEvents.compactMap { event -> Int? in
                guard case let .sleep(sleep) = event, let endedAt = sleep.endedAt else { return nil }
                return max(1, Int(endedAt.timeIntervalSince(sleep.startedAt) / 60))
            }.reduce(0, +)
            return DailySleepData(
                date: date,
                label: formatter(date),
                totalMinutes: sleepMinutes
            )
        }

        let dailyNappy = dates.map { date -> DailyNappyData in
            let dayEvents = eventsByDay[date] ?? []
            let nappies = dayEvents.compactMap { event -> NappyEvent? in
                guard case let .nappy(nappy) = event else { return nil }
                return nappy
            }
            return DailyNappyData(
                date: date,
                label: formatter(date),
                wetCount: nappies.filter { $0.type == .wee }.count,
                dirtyCount: nappies.filter { $0.type == .poo }.count,
                mixedCount: nappies.filter { $0.type == .mixed }.count,
                dryCount: nappies.filter { $0.type == .dry }.count
            )
        }

        return TrendsSummaryData(
            dailyBottle: dailyBottle,
            dailyBreastFeed: dailyBreastFeed,
            dailySleep: dailySleep,
            dailyNappy: dailyNappy,
            avgDailyBottleMilliliters: average(of: dailyBottle.filter { $0.count > 0 }.map(\.totalMilliliters)),
            avgDailyBreastFeedSessions: average(of: dailyBreastFeed.filter { $0.sessionCount > 0 }.map(\.sessionCount)),
            avgDailySleepMinutes: average(of: dailySleep.filter { $0.totalMinutes > 0 }.map(\.totalMinutes)),
            avgDailyNappies: average(of: dailyNappy.filter { $0.totalCount > 0 }.map(\.totalCount))
        )
    }

    // MARK: - Private helpers

    private static func filter(
        events: [BabyEvent],
        range: TrendsTimeRange,
        now: Date,
        calendar: Calendar
    ) -> [BabyEvent] {
        switch range {
        case .allTime:
            return events
        case .sevenDays:
            return events.filter { isWithinDays($0.metadata.occurredAt, days: 7, now: now, calendar: calendar) }
        case .thirtyDays:
            return events.filter { isWithinDays($0.metadata.occurredAt, days: 30, now: now, calendar: calendar) }
        }
    }

    private static func isWithinDays(_ date: Date, days: Int, now: Date, calendar: Calendar) -> Bool {
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now)) else {
            return false
        }
        return date >= start && date <= now
    }

    private static func makeDates(
        range: TrendsTimeRange,
        events: [BabyEvent],
        now: Date,
        calendar: Calendar
    ) -> [Date] {
        switch range {
        case .sevenDays:
            return trailingDates(dayCount: 7, now: now, calendar: calendar)
        case .thirtyDays:
            return trailingDates(dayCount: 30, now: now, calendar: calendar)
        case .allTime:
            let days = Set(events.map { calendar.startOfDay(for: $0.metadata.occurredAt) }).sorted()
            guard let first = days.first else { return [] }
            return strideDates(from: first, through: calendar.startOfDay(for: now), calendar: calendar)
        }
    }

    private static func trailingDates(dayCount: Int, now: Date, calendar: Calendar) -> [Date] {
        let end = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -(dayCount - 1), to: end) else {
            return []
        }
        return strideDates(from: start, through: end, calendar: calendar)
    }

    private static func strideDates(from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        var dates: [Date] = []
        var current = calendar.startOfDay(for: start)
        let finalDate = calendar.startOfDay(for: end)

        while current <= finalDate {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return dates
    }

    /// Returns a label formatter appropriate for the number of days being shown.
    /// Fewer days → day-of-week labels; more days → short date labels.
    private static func makeDayFormatter(
        calendar: Calendar,
        totalDays: Int
    ) -> (Date) -> String {
        if totalDays <= 14 {
            // Narrow weekday: M, T, W …
            return { date in date.formatted(.dateTime.weekday(.narrow)) }
        } else if totalDays <= 60 {
            // Short date: Jan 5
            let fmt = DateFormatter()
            fmt.calendar = calendar
            fmt.locale = .autoupdatingCurrent
            fmt.setLocalizedDateFormatFromTemplate("MMMd")
            return { date in fmt.string(from: date) }
        } else {
            // Month/year: Jan, Feb …
            let fmt = DateFormatter()
            fmt.calendar = calendar
            fmt.locale = .autoupdatingCurrent
            fmt.setLocalizedDateFormatFromTemplate("MMM")
            return { date in fmt.string(from: date) }
        }
    }

    private static func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }
}
