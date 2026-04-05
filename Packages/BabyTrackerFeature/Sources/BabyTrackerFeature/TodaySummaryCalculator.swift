import BabyTrackerDomain
import Foundation

public enum TodaySummaryCalculator {
    public static func makeData(
        from allEvents: [BabyEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TodaySummaryData {
        let todayEvents = allEvents.filter {
            calendar.isDate($0.metadata.occurredAt, inSameDayAs: now)
        }

        // Bottle feeds
        let bottleFeeds = todayEvents.compactMap { event -> BottleFeedEvent? in
            guard case let .bottleFeed(feed) = event else { return nil }
            return feed
        }
        let bottleTotalMilliliters = bottleFeeds.reduce(0) { $0 + $1.amountMilliliters }
        let formulaMilliliters = bottleFeeds
            .filter { $0.milkType == .formula }
            .reduce(0) { $0 + $1.amountMilliliters }
        let breastMilkMilliliters = bottleFeeds
            .filter { $0.milkType == .breastMilk }
            .reduce(0) { $0 + $1.amountMilliliters }
        let mixedMilkMilliliters = bottleFeeds
            .filter { $0.milkType == .mixed }
            .reduce(0) { $0 + $1.amountMilliliters }

        // Breast feeds
        let breastFeeds = todayEvents.compactMap { event -> BreastFeedEvent? in
            guard case let .breastFeed(feed) = event else { return nil }
            return feed
        }
        let breastFeedDurations = breastFeeds.map { feed in
            max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
        }
        let breastFeedTotalMinutes = breastFeedDurations.reduce(0, +)
        let averageBreastFeedMinutes = average(of: breastFeedDurations)

        // Average feed interval (all feeds combined, by occurredAt time)
        let allFeedEvents = todayEvents.filter {
            switch $0 {
            case .breastFeed, .bottleFeed: true
            case .sleep, .nappy: false
            }
        }
        let averageFeedInterval = averageFeedIntervalMinutes(for: allFeedEvents)

        // Time since last feed
        let lastFeedDate = allFeedEvents.map(\.metadata.occurredAt).max()
        let minutesSinceLastFeed = lastFeedDate.map {
            max(0, Int(now.timeIntervalSince($0) / 60))
        }

        // Sleep
        let completedSleeps = todayEvents.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleep) = event, sleep.endedAt != nil else { return nil }
            return sleep
        }
        let sleepDurations = completedSleeps.compactMap { sleepDurationMinutes(for: $0) }
        let totalSleepMinutes = sleepDurations.reduce(0, +)
        let longestSleepBlock = sleepDurations.max()

        var daytimeSleepMinutes = 0
        var nighttimeSleepMinutes = 0
        for sleep in completedSleeps {
            let (daytime, nighttime) = splitSleepDuration(sleep, calendar: calendar)
            daytimeSleepMinutes += daytime
            nighttimeSleepMinutes += nighttime
        }

        // Nappies
        let nappies = todayEvents.compactMap { event -> NappyEvent? in
            guard case let .nappy(nappy) = event else { return nil }
            return nappy
        }
        let wetCount = nappies.filter { $0.type == .wee }.count
        let dirtyCount = nappies.filter { $0.type == .poo }.count
        let mixedCount = nappies.filter { $0.type == .mixed }.count

        // Logging streak (uses all events, not just today)
        let streak = loggingStreakDays(from: allEvents, now: now, calendar: calendar)

        return TodaySummaryData(
            bottleTotalMilliliters: bottleTotalMilliliters,
            bottleCount: bottleFeeds.count,
            formulaMilliliters: formulaMilliliters,
            breastMilkMilliliters: breastMilkMilliliters,
            mixedMilkMilliliters: mixedMilkMilliliters,
            breastFeedTotalMinutes: breastFeedTotalMinutes,
            breastFeedCount: breastFeeds.count,
            averageBreastFeedMinutes: averageBreastFeedMinutes,
            averageFeedIntervalMinutes: averageFeedInterval,
            minutesSinceLastFeed: minutesSinceLastFeed,
            totalSleepMinutes: totalSleepMinutes,
            daytimeSleepMinutes: daytimeSleepMinutes,
            nighttimeSleepMinutes: nighttimeSleepMinutes,
            longestSleepBlockMinutes: longestSleepBlock,
            totalNappies: nappies.count,
            wetNappyCount: wetCount,
            dirtyNappyCount: dirtyCount,
            mixedNappyCount: mixedCount,
            wetInclusiveCount: wetCount + mixedCount,
            dirtyInclusiveCount: dirtyCount + mixedCount,
            loggingStreakDays: streak
        )
    }

    // MARK: - Private helpers

    private static func sleepDurationMinutes(for event: SleepEvent) -> Int? {
        guard let endedAt = event.endedAt else { return nil }
        return max(1, Int(endedAt.timeIntervalSince(event.startedAt) / 60))
    }

    /// Splits a completed sleep block into daytime (6am–10pm) and nighttime (10pm–6am) minutes.
    private static func splitSleepDuration(
        _ sleep: SleepEvent,
        calendar: Calendar
    ) -> (daytime: Int, nighttime: Int) {
        guard let endedAt = sleep.endedAt else { return (0, 0) }

        let totalMinutes = max(0, Int(endedAt.timeIntervalSince(sleep.startedAt) / 60))
        guard totalMinutes > 0 else { return (0, 0) }

        // Build the 10pm and 6am boundaries for the day the sleep started.
        let startDay = calendar.startOfDay(for: sleep.startedAt)
        guard
            let tenPm = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: startDay),
            let sixAm = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: startDay),
            let nextSixAm = calendar.date(byAdding: .day, value: 1, to: sixAm)
        else {
            return (totalMinutes, 0)
        }

        // Collect nighttime intervals: [midnight–6am] and [10pm–midnight]
        var nighttimeMinutes = 0

        let intervals: [(Date, Date)] = [
            (startDay, sixAm),       // midnight–6am
            (tenPm, nextSixAm)       // 10pm–next 6am
        ]

        for (nightStart, nightEnd) in intervals {
            let overlapStart = max(sleep.startedAt, nightStart)
            let overlapEnd = min(endedAt, nightEnd)
            if overlapEnd > overlapStart {
                nighttimeMinutes += Int(overlapEnd.timeIntervalSince(overlapStart) / 60)
            }
        }

        let daytimeMinutes = max(0, totalMinutes - nighttimeMinutes)
        return (daytimeMinutes, nighttimeMinutes)
    }

    private static func averageFeedIntervalMinutes(for feedEvents: [BabyEvent]) -> Int? {
        let sortedTimes = feedEvents.map(\.metadata.occurredAt).sorted()
        guard sortedTimes.count > 1 else { return nil }

        var intervals: [Int] = []
        for index in 1..<sortedTimes.count {
            let interval = sortedTimes[index].timeIntervalSince(sortedTimes[index - 1])
            intervals.append(max(1, Int(interval / 60)))
        }

        guard !intervals.isEmpty else { return nil }
        return Int((Double(intervals.reduce(0, +)) / Double(intervals.count)).rounded())
    }

    private static func loggingStreakDays(
        from events: [BabyEvent],
        now: Date,
        calendar: Calendar
    ) -> Int {
        let daySet = Set(events.map { calendar.startOfDay(for: $0.metadata.occurredAt) })
        guard !daySet.isEmpty else { return 0 }

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
}
