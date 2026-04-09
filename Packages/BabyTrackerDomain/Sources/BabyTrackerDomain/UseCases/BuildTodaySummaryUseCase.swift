import Foundation

public protocol TodaySummaryBuilding: Sendable {
    func execute(
        events: [BabyEvent],
        now: Date,
        calendar: Calendar
    ) -> TodaySummary
}

public struct BuildTodaySummaryUseCase: TodaySummaryBuilding {
    public init() {}

    public func execute(
        events: [BabyEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TodaySummary {
        let todayEvents = events.filter {
            calendar.isDate($0.metadata.occurredAt, inSameDayAs: now)
        }

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

        let breastFeeds = todayEvents.compactMap { event -> BreastFeedEvent? in
            guard case let .breastFeed(feed) = event else { return nil }
            return feed
        }
        let breastFeedDurations = breastFeeds.map { feed in
            max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
        }
        let breastFeedTotalMinutes = breastFeedDurations.reduce(0, +)
        let averageBreastFeedMinutes = average(of: breastFeedDurations)

        let allFeedEvents = todayEvents.filter {
            switch $0 {
            case .breastFeed, .bottleFeed: true
            case .sleep, .nappy: false
            }
        }
        let averageFeedInterval = averageFeedIntervalMinutes(for: allFeedEvents)

        let lastFeedDate = allFeedEvents.map(\.metadata.occurredAt).max()
        let minutesSinceLastFeed = lastFeedDate.map {
            max(0, Int(now.timeIntervalSince($0) / 60))
        }

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

        let nappies = todayEvents.compactMap { event -> NappyEvent? in
            guard case let .nappy(nappy) = event else { return nil }
            return nappy
        }
        let wetCount = nappies.filter { $0.type == .wee }.count
        let dirtyCount = nappies.filter { $0.type == .poo }.count
        let mixedCount = nappies.filter { $0.type == .mixed }.count

        let streak = loggingStreakDays(from: events, now: now, calendar: calendar)

        return TodaySummary(
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

    private func sleepDurationMinutes(for event: SleepEvent) -> Int? {
        guard let endedAt = event.endedAt else { return nil }
        return max(1, Int(endedAt.timeIntervalSince(event.startedAt) / 60))
    }

    private func splitSleepDuration(
        _ sleep: SleepEvent,
        calendar: Calendar
    ) -> (daytime: Int, nighttime: Int) {
        guard let endedAt = sleep.endedAt else { return (0, 0) }

        let totalMinutes = max(0, Int(endedAt.timeIntervalSince(sleep.startedAt) / 60))
        guard totalMinutes > 0 else { return (0, 0) }

        let startDay = calendar.startOfDay(for: sleep.startedAt)
        guard
            let tenPm = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: startDay),
            let sixAm = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: startDay),
            let nextSixAm = calendar.date(byAdding: .day, value: 1, to: sixAm)
        else {
            return (totalMinutes, 0)
        }

        var nighttimeMinutes = 0

        let intervals: [(Date, Date)] = [
            (startDay, sixAm),
            (tenPm, nextSixAm),
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

    private func averageFeedIntervalMinutes(for feedEvents: [BabyEvent]) -> Int? {
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

    private func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    private func loggingStreakDays(
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
