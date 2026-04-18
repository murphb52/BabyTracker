import BabyTrackerDomain
import Foundation

public enum TodaySummaryCalculator {
    public static func makeData(
        from allEvents: [BabyEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TodaySummaryData {
        makeData(
            from: allEvents,
            day: now,
            referenceNow: now,
            calendar: calendar
        )
    }

    public static func makeData(
        from allEvents: [BabyEvent],
        day: Date,
        referenceNow: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TodaySummaryData {
        let selectedDay = calendar.startOfDay(for: day)
        let isSelectedDayToday = calendar.isDate(selectedDay, inSameDayAs: referenceNow)
        let effectiveNow = if isSelectedDayToday {
            referenceNow
        } else {
            calendar.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
        }

        let todayEvents = allEvents.filter {
            calendar.isDate($0.metadata.occurredAt, inSameDayAs: selectedDay)
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
            max(0, Int(effectiveNow.timeIntervalSince($0) / 60))
        }

        // Sleep - current active session state is only meaningful for the actual current day.
        let activeSleep = allEvents.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleep) = event, sleep.endedAt == nil else { return nil }
            return sleep
        }
        .filter { sleep in
            sleep.startedAt < effectiveNow
        }
        .sorted { $0.startedAt > $1.startedAt }
        .first

        let completedSleeps = todayEvents.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleep) = event, sleep.endedAt != nil else { return nil }
            return sleep
        }

        let overlappingSleeps = allEvents.compactMap { event -> SleepEvent? in
            guard case let .sleep(sleep) = event else { return nil }
            return sleep
        }
        .filter { sleep in
            sleepMinutesOnSelectedDay(
                for: sleep,
                day: selectedDay,
                effectiveNow: effectiveNow,
                calendar: calendar
            ) > 0
        }

        let allSleepDurations = overlappingSleeps.map { sleep in
            sleepMinutesOnSelectedDay(
                for: sleep,
                day: selectedDay,
                effectiveNow: effectiveNow,
                calendar: calendar
            )
        }

        let totalSleepMinutes = allSleepDurations.reduce(0, +)
        let longestSleepBlock = allSleepDurations.max()
        let shortestSleepBlock = allSleepDurations.min()
        let averageSleepBlock = average(of: allSleepDurations)

        // Time since last sleep - nil while actively sleeping
        let minutesSinceLastSleep: Int?
        if isSelectedDayToday && activeSleep != nil {
            minutesSinceLastSleep = nil
        } else {
            let lastSleepEndDate = completedSleeps.compactMap(\.endedAt).max()
            minutesSinceLastSleep = lastSleepEndDate.map {
                max(0, Int(effectiveNow.timeIntervalSince($0) / 60))
            }
        }

        var daytimeSleepMinutes = 0
        var nighttimeSleepMinutes = 0
        for sleep in overlappingSleeps {
            let (daytime, nighttime) = splitSleepDurationOnSelectedDay(
                sleep,
                day: selectedDay,
                effectiveNow: effectiveNow,
                calendar: calendar
            )
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
        let dryCount = nappies.filter { $0.type == .dry }.count

        // Logging streak (uses all events, not just today)
        let streak = loggingStreakDays(from: allEvents, now: effectiveNow, calendar: calendar)

        // Hourly cumulative chart data
        let chartData = makeChartData(
            from: allEvents,
            selectedDay: selectedDay,
            effectiveNow: effectiveNow,
            calendar: calendar
        )

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
            shortestSleepBlockMinutes: shortestSleepBlock,
            averageSleepBlockMinutes: averageSleepBlock,
            minutesSinceLastSleep: minutesSinceLastSleep,
            totalNappies: nappies.count,
            wetNappyCount: wetCount,
            dirtyNappyCount: dirtyCount,
            mixedNappyCount: mixedCount,
            dryNappyCount: dryCount,
            wetInclusiveCount: wetCount + mixedCount,
            dirtyInclusiveCount: dirtyCount + mixedCount,
            loggingStreakDays: streak,
            chartData: chartData
        )
    }

    // MARK: - Chart data

    private static func makeChartData(
        from allEvents: [BabyEvent],
        selectedDay: Date,
        effectiveNow: Date,
        calendar: Calendar
    ) -> TodayChartData {
        let today = calendar.startOfDay(for: selectedDay)
        let todayEvents = allEvents.filter { calendar.isDate($0.metadata.occurredAt, inSameDayAs: today) }

        // Collect the 7 complete days before today
        let historicalDays: [[BabyEvent]] = (1...7).compactMap { offset -> [BabyEvent]? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return allEvents.filter { calendar.isDate($0.metadata.occurredAt, inSameDayAs: day) }
        }

        return TodayChartData(
            bottle: buildCumulativeSeries(
                todayAmounts: bottleHourlyAmounts(events: todayEvents, calendar: calendar),
                historicalAmounts: historicalDays.map { bottleHourlyAmounts(events: $0, calendar: calendar) }
            ),
            bottleFormula: buildCumulativeSeries(
                todayAmounts: bottleHourlyAmounts(events: todayEvents, calendar: calendar, includes: { $0.milkType == .formula }),
                historicalAmounts: historicalDays.map {
                    bottleHourlyAmounts(events: $0, calendar: calendar, includes: { $0.milkType == .formula })
                }
            ),
            bottleBreastMilk: buildCumulativeSeries(
                todayAmounts: bottleHourlyAmounts(events: todayEvents, calendar: calendar, includes: { $0.milkType == .breastMilk }),
                historicalAmounts: historicalDays.map {
                    bottleHourlyAmounts(events: $0, calendar: calendar, includes: { $0.milkType == .breastMilk })
                }
            ),
            bottleMixed: buildCumulativeSeries(
                todayAmounts: bottleHourlyAmounts(events: todayEvents, calendar: calendar, includes: { $0.milkType == .mixed }),
                historicalAmounts: historicalDays.map {
                    bottleHourlyAmounts(events: $0, calendar: calendar, includes: { $0.milkType == .mixed })
                }
            ),
            bottleFormulaIncludingMixed: buildCumulativeSeries(
                todayAmounts: bottleHourlyAmounts(
                    events: todayEvents,
                    calendar: calendar,
                    includes: { $0.milkType == .formula || $0.milkType == .mixed }
                ),
                historicalAmounts: historicalDays.map {
                    bottleHourlyAmounts(
                        events: $0,
                        calendar: calendar,
                        includes: { $0.milkType == .formula || $0.milkType == .mixed }
                    )
                }
            ),
            bottleBreastMilkIncludingMixed: buildCumulativeSeries(
                todayAmounts: bottleHourlyAmounts(
                    events: todayEvents,
                    calendar: calendar,
                    includes: { $0.milkType == .breastMilk || $0.milkType == .mixed }
                ),
                historicalAmounts: historicalDays.map {
                    bottleHourlyAmounts(
                        events: $0,
                        calendar: calendar,
                        includes: { $0.milkType == .breastMilk || $0.milkType == .mixed }
                    )
                }
            ),
            breast: buildCumulativeSeries(
                todayAmounts: breastHourlyAmounts(events: todayEvents, calendar: calendar),
                historicalAmounts: historicalDays.map { breastHourlyAmounts(events: $0, calendar: calendar) }
            ),
            sleep: buildCumulativeSeries(
                todayAmounts: sleepHourlyAmounts(
                    allEvents: allEvents,
                    day: today,
                    now: effectiveNow,
                    calendar: calendar
                ),
                historicalAmounts: (1...7).compactMap { offset -> [Int]? in
                    guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                          let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
                    return sleepHourlyAmounts(allEvents: allEvents, day: day, now: dayEnd, calendar: calendar)
                }
            ),
            nappy: buildCumulativeSeries(
                todayAmounts: nappyHourlyAmounts(events: todayEvents, calendar: calendar),
                historicalAmounts: historicalDays.map { nappyHourlyAmounts(events: $0, calendar: calendar) }
            ),
            nappyPee: buildCumulativeSeries(
                todayAmounts: nappyHourlyAmounts(events: todayEvents, calendar: calendar, includes: { $0.type == .wee }),
                historicalAmounts: historicalDays.map {
                    nappyHourlyAmounts(events: $0, calendar: calendar, includes: { $0.type == .wee })
                }
            ),
            nappyPoo: buildCumulativeSeries(
                todayAmounts: nappyHourlyAmounts(events: todayEvents, calendar: calendar, includes: { $0.type == .poo }),
                historicalAmounts: historicalDays.map {
                    nappyHourlyAmounts(events: $0, calendar: calendar, includes: { $0.type == .poo })
                }
            ),
            nappyMixed: buildCumulativeSeries(
                todayAmounts: nappyHourlyAmounts(events: todayEvents, calendar: calendar, includes: { $0.type == .mixed }),
                historicalAmounts: historicalDays.map {
                    nappyHourlyAmounts(events: $0, calendar: calendar, includes: { $0.type == .mixed })
                }
            ),
            nappyPeeIncludingMixed: buildCumulativeSeries(
                todayAmounts: nappyHourlyAmounts(
                    events: todayEvents,
                    calendar: calendar,
                    includes: { $0.type == .wee || $0.type == .mixed }
                ),
                historicalAmounts: historicalDays.map {
                    nappyHourlyAmounts(
                        events: $0,
                        calendar: calendar,
                        includes: { $0.type == .wee || $0.type == .mixed }
                    )
                }
            ),
            nappyPooIncludingMixed: buildCumulativeSeries(
                todayAmounts: nappyHourlyAmounts(
                    events: todayEvents,
                    calendar: calendar,
                    includes: { $0.type == .poo || $0.type == .mixed }
                ),
                historicalAmounts: historicalDays.map {
                    nappyHourlyAmounts(
                        events: $0,
                        calendar: calendar,
                        includes: { $0.type == .poo || $0.type == .mixed }
                    )
                }
            )
        )
    }

    /// Builds a `HourlyCumulativeSeries` from per-hour amounts.
    /// - Parameters:
    ///   - todayAmounts: 24 per-hour amounts for today.
    ///   - historicalAmounts: Up to 7 arrays of per-hour amounts for prior days.
    ///                        Always divides by 7 so zero-activity days reduce the average naturally.
    private static func buildCumulativeSeries(
        todayAmounts: [Int],
        historicalAmounts: [[Int]]
    ) -> HourlyCumulativeSeries {
        let todayCumulative = cumulativeSum(of: todayAmounts)

        var avgCumulative = [Int](repeating: 0, count: 24)
        for h in 0..<24 {
            let historicalCumulativeAtH = historicalAmounts.map { amounts -> Int in
                cumulativeSum(of: amounts)[h]
            }
            let sum = historicalCumulativeAtH.reduce(0, +)
            avgCumulative[h] = sum / 7
        }

        return HourlyCumulativeSeries(todayCumulative: todayCumulative, averageCumulative: avgCumulative)
    }

    private static func cumulativeSum(of amounts: [Int]) -> [Int] {
        var result = [Int](repeating: 0, count: 24)
        var running = 0
        for h in 0..<min(amounts.count, 24) {
            running += amounts[h]
            result[h] = running
        }
        return result
    }

    // MARK: - Per-hour amounts

    /// Returns a 24-element array where index h = total bottle mL from feeds whose occurredAt is in hour h.
    private static func bottleHourlyAmounts(
        events: [BabyEvent],
        calendar: Calendar,
        includes: (BottleFeedEvent) -> Bool = { _ in true }
    ) -> [Int] {
        var amounts = [Int](repeating: 0, count: 24)
        for event in events {
            guard case let .bottleFeed(feed) = event else { continue }
            guard includes(feed) else { continue }
            let h = calendar.component(.hour, from: feed.metadata.occurredAt)
            amounts[h] += feed.amountMilliliters
        }
        return amounts
    }

    /// Returns a 24-element array where index h = number of breast feed sessions whose endedAt is in hour h.
    private static func breastHourlyAmounts(events: [BabyEvent], calendar: Calendar) -> [Int] {
        var amounts = [Int](repeating: 0, count: 24)
        for event in events {
            guard case let .breastFeed(feed) = event else { continue }
            let h = calendar.component(.hour, from: feed.endedAt)
            amounts[h] += 1
        }
        return amounts
    }

    /// Returns a 24-element array where index h = minutes of sleep overlapping hour h on `day`.
    /// Minutes are distributed across each hour the sleep actually occupied, rather than
    /// being attributed to the endedAt hour. Active sleep (endedAt == nil) is counted up to `now`.
    /// Sleep that started before `day` (e.g. an overnight session) is also included.
    private static func sleepHourlyAmounts(
        allEvents: [BabyEvent],
        day: Date,
        now: Date,
        calendar: Calendar
    ) -> [Int] {
        var amounts = [Int](repeating: 0, count: 24)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { return amounts }
        let cap = min(now, dayEnd)

        for event in allEvents {
            guard case let .sleep(sleep) = event else { continue }
            let effectiveEnd = sleep.endedAt ?? now

            // Skip sessions that don't overlap with this day at all
            guard effectiveEnd > day && sleep.startedAt < cap else { continue }

            for h in 0..<24 {
                guard let hourStart = calendar.date(byAdding: .hour, value: h, to: day),
                      let hourEnd = calendar.date(byAdding: .hour, value: h + 1, to: day)
                else { continue }

                let overlapStart = max(sleep.startedAt, hourStart)
                let overlapEnd = min(effectiveEnd, min(hourEnd, cap))

                if overlapEnd > overlapStart {
                    amounts[h] += max(0, Int(overlapEnd.timeIntervalSince(overlapStart) / 60))
                }
            }
        }

        return amounts
    }

    /// Returns a 24-element array where index h = number of nappy changes in hour h (by occurredAt).
    private static func nappyHourlyAmounts(
        events: [BabyEvent],
        calendar: Calendar,
        includes: (NappyEvent) -> Bool = { _ in true }
    ) -> [Int] {
        var amounts = [Int](repeating: 0, count: 24)
        for event in events {
            guard case let .nappy(nappy) = event else { continue }
            guard includes(nappy) else { continue }
            let h = calendar.component(.hour, from: nappy.metadata.occurredAt)
            amounts[h] += 1
        }
        return amounts
    }

    // MARK: - Private helpers

    private static func sleepDurationMinutes(for event: SleepEvent) -> Int? {
        guard let endedAt = event.endedAt else { return nil }
        return max(1, Int(endedAt.timeIntervalSince(event.startedAt) / 60))
    }

    private static func sleepMinutesOnSelectedDay(
        for sleep: SleepEvent,
        day: Date,
        effectiveNow: Date,
        calendar: Calendar
    ) -> Int {
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { return 0 }

        let effectiveEnd = sleep.endedAt ?? effectiveNow
        let cap = min(effectiveNow, dayEnd)

        guard effectiveEnd > day && sleep.startedAt < cap else { return 0 }

        let overlapStart = max(sleep.startedAt, day)
        let overlapEnd = min(effectiveEnd, cap)
        guard overlapEnd > overlapStart else { return 0 }

        return max(0, Int(overlapEnd.timeIntervalSince(overlapStart) / 60))
    }

    /// Splits a sleep block into daytime (6am–10pm) and nighttime (10pm–6am) minutes.
    /// Pass `effectiveEnd` for active (in-progress) sessions; otherwise `sleep.endedAt` is used.
    private static func splitSleepDuration(
        _ sleep: SleepEvent,
        effectiveEnd: Date? = nil,
        calendar: Calendar
    ) -> (daytime: Int, nighttime: Int) {
        guard let endedAt = sleep.endedAt ?? effectiveEnd else { return (0, 0) }

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

    private static func splitSleepDurationOnSelectedDay(
        _ sleep: SleepEvent,
        day: Date,
        effectiveNow: Date,
        calendar: Calendar
    ) -> (daytime: Int, nighttime: Int) {
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { return (0, 0) }

        let effectiveEnd = sleep.endedAt ?? effectiveNow
        let cap = min(effectiveNow, dayEnd)
        let overlapStart = max(sleep.startedAt, day)
        let overlapEnd = min(effectiveEnd, cap)

        guard overlapEnd > overlapStart else { return (0, 0) }

        var daytimeMinutes = 0
        var nighttimeMinutes = 0
        var cursor = overlapStart

        while cursor < overlapEnd {
            guard let nextBoundary = calendar.date(byAdding: .minute, value: 1, to: cursor) else { break }
            let minuteEnd = min(nextBoundary, overlapEnd)
            let hour = calendar.component(.hour, from: cursor)

            if (6..<22).contains(hour) {
                daytimeMinutes += Int(minuteEnd.timeIntervalSince(cursor) / 60)
            } else {
                nighttimeMinutes += Int(minuteEnd.timeIntervalSince(cursor) / 60)
            }

            cursor = minuteEnd
        }

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

    private static func average(of values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
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
