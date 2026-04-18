import BabyTrackerDomain
import Foundation

public enum AdvancedSummaryMetricsCalculator {
    public static func makeViewState(
        from events: [BabyEvent],
        selection: AdvancedSummarySelection,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> AdvancedSummaryViewState {
        let filteredEvents = filter(
            events: events.sorted { $0.metadata.occurredAt < $1.metadata.occurredAt },
            selection: selection,
            now: now,
            calendar: calendar
        )

        let breastFeeds = filteredEvents.compactMap { event -> BreastFeedEvent? in
            guard case let .breastFeed(feed) = event else { return nil }
            return feed
        }
        let bottleFeeds = filteredEvents.compactMap { event -> BottleFeedEvent? in
            guard case let .bottleFeed(feed) = event else { return nil }
            return feed
        }
        let completedSleeps = filteredEvents.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleep) = event, sleep.endedAt != nil else { return nil }
            return sleep
        }
        let nappies = filteredEvents.compactMap { event -> NappyEvent? in
            guard case let .nappy(nappy) = event else { return nil }
            return nappy
        }

        let sleepDurations = completedSleeps.compactMap(sleepDurationMinutes(for:))
        let hourlyActivityCounts = makeHourlyActivityCounts(events: filteredEvents, calendar: calendar)
        let busiestHour = hourlyActivityCounts.max { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.hour > rhs.hour
            }

            return lhs.count < rhs.count
        }

        return AdvancedSummaryViewState(
            eventCount: filteredEvents.count,
            totalFeeds: breastFeeds.count + bottleFeeds.count,
            breastFeedCount: breastFeeds.count,
            bottleFeedCount: bottleFeeds.count,
            averageBottleVolumeMilliliters: average(of: bottleFeeds.map(\.amountMilliliters)),
            totalSleepMinutes: sleepDurations.reduce(0, +),
            completedSleepCount: completedSleeps.count,
            averageSleepBlockMinutes: average(of: sleepDurations),
            longestSleepBlockMinutes: sleepDurations.max(),
            totalNappies: nappies.count,
            wetNappyCount: nappies.filter { $0.type == .wee }.count,
            dirtyNappyCount: nappies.filter { $0.type == .poo }.count,
            mixedNappyCount: nappies.filter { $0.type == .mixed }.count,
            dryNappyCount: nappies.filter { $0.type == .dry }.count,
            busiestHourLabel: busiestHour.map(\.label),
            busiestHourCount: busiestHour?.count ?? 0,
            dailyActivityCounts: makeDailyActivityCounts(
                events: filteredEvents,
                selection: selection,
                now: now,
                calendar: calendar
            ),
            hourlyActivityCounts: hourlyActivityCounts
        )
    }

    private static func filter(
        events: [BabyEvent],
        selection: AdvancedSummarySelection,
        now: Date,
        calendar: Calendar
    ) -> [BabyEvent] {
        switch selection.mode {
        case .range:
            switch selection.range {
            case .allTime:
                return events
            case .today:
                return events.filter { calendar.isDate($0.metadata.occurredAt, inSameDayAs: now) }
            case .sevenDays:
                return events.filter { isWithinDays($0.metadata.occurredAt, days: 7, now: now, calendar: calendar) }
            case .thirtyDays:
                return events.filter { isWithinDays($0.metadata.occurredAt, days: 30, now: now, calendar: calendar) }
            }
        case .day:
            let start = calendar.startOfDay(for: selection.day)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                return []
            }

            return events.filter { $0.metadata.occurredAt >= start && $0.metadata.occurredAt < end }
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

    private static func sleepDurationMinutes(for event: SleepEvent) -> Int? {
        guard let endedAt = event.endedAt else {
            return nil
        }

        return max(1, Int(endedAt.timeIntervalSince(event.startedAt) / 60))
    }

    private static func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else {
            return nil
        }

        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    private static func makeDailyActivityCounts(
        events: [BabyEvent],
        selection: AdvancedSummarySelection,
        now: Date,
        calendar: Calendar
    ) -> [SummaryDayCount] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE")

        let countsByDay = Dictionary(
            grouping: events,
            by: { calendar.startOfDay(for: $0.metadata.occurredAt) }
        ).mapValues(\.count)

        let dates: [Date]
        switch selection.mode {
        case .range:
            switch selection.range {
            case .today:
                dates = [calendar.startOfDay(for: now)]
            case .sevenDays:
                dates = trailingDates(dayCount: 7, now: now, calendar: calendar)
            case .thirtyDays:
                dates = trailingDates(dayCount: 30, now: now, calendar: calendar)
            case .allTime:
                if let firstDay = countsByDay.keys.sorted().first {
                    dates = strideDates(from: firstDay, through: calendar.startOfDay(for: now), calendar: calendar)
                } else {
                    dates = []
                }
            }
        case .day:
            dates = [calendar.startOfDay(for: selection.day)]
        }

        return dates.map { date in
            SummaryDayCount(
                date: date,
                label: formatter.string(from: date),
                count: countsByDay[date, default: 0]
            )
        }
    }

    private static func makeHourlyActivityCounts(
        events: [BabyEvent],
        calendar: Calendar
    ) -> [SummaryHourCount] {
        let countsByHour = Dictionary(
            grouping: events,
            by: { calendar.component(.hour, from: $0.metadata.occurredAt) }
        ).mapValues(\.count)

        return (0..<24).map { hour in
            return SummaryHourCount(
                hour: hour,
                label: hourLabel(for: hour),
                count: countsByHour[hour, default: 0]
            )
        }
    }

    private static func hourLabel(for hour: Int) -> String {
        let normalizedHour = hour % 24
        let meridiem = normalizedHour < 12 ? "AM" : "PM"
        let displayHour = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12
        return "\(displayHour)\(meridiem)"
    }

    private static func trailingDates(
        dayCount: Int,
        now: Date,
        calendar: Calendar
    ) -> [Date] {
        let end = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -(dayCount - 1), to: end) else {
            return []
        }

        return strideDates(from: start, through: end, calendar: calendar)
    }

    private static func strideDates(
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) -> [Date] {
        var dates: [Date] = []
        var current = calendar.startOfDay(for: start)
        let finalDate = calendar.startOfDay(for: end)

        while current <= finalDate {
            dates.append(current)

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }

            current = next
        }

        return dates
    }
}
