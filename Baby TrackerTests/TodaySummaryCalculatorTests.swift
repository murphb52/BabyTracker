import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct TodaySummaryCalculatorTests {
    @Test
    func makeDataIncludesBottleMilkBreakdownAndBreastSessionAverage() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        let bottleOneTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 7, minute: 0)))
        let bottleTwoTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 8, minute: 0)))
        let breastEndTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9, minute: 0)))

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: bottleOneTime,
                        createdAt: bottleOneTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 120,
                    milkType: .formula
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: bottleTwoTime,
                        createdAt: bottleTwoTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 90,
                    milkType: .breastMilk
                )
            ),
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: breastEndTime,
                        createdAt: breastEndTime,
                        createdBy: userID
                    ),
                    side: .left,
                    startedAt: breastEndTime.addingTimeInterval(-1_200),
                    endedAt: breastEndTime
                )
            ),
        ]

        let data = TodaySummaryCalculator.makeData(
            from: events,
            now: now,
            calendar: calendar
        )

        #expect(data.bottleCount == 2)
        #expect(data.bottleTotalMilliliters == 210)
        #expect(data.formulaMilliliters == 120)
        #expect(data.breastMilkMilliliters == 90)
        #expect(data.mixedMilkMilliliters == 0)
        #expect(data.breastFeedCount == 1)
        #expect(data.breastFeedTotalMinutes == 20)
        #expect(data.averageBreastFeedMinutes == 20)
    }

    // MARK: - Hourly cumulative chart tests

    @Test
    func bottleChartSeriesAlwaysHasTwentyFourValues() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        let data = TodaySummaryCalculator.makeData(from: [], now: now, calendar: calendar)

        #expect(data.chartData.bottle.todayCumulative.count == 24)
        #expect(data.chartData.bottle.averageCumulative.count == 24)
    }

    @Test
    func bottleChartSeriesTodayAccumulatesCorrectly() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 15)))
        let nineAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9)))
        let twoPm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 14)))

        let events: [BabyEvent] = [
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: nineAm, createdAt: nineAm, createdBy: userID),
                amountMilliliters: 100,
                milkType: .formula
            )),
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: twoPm, createdAt: twoPm, createdBy: userID),
                amountMilliliters: 150,
                milkType: .formula
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)
        let today = data.chartData.bottle.todayCumulative

        // Before the first feed: zero
        #expect(today[8] == 0)
        // After the 9am feed: 100 mL cumulative
        #expect(today[9] == 100)
        // Between feeds: stays at 100
        #expect(today[13] == 100)
        // After the 2pm feed: 250 mL cumulative
        #expect(today[14] == 250)
        // End of day: still 250
        #expect(today[23] == 250)
    }

    @Test
    func sevenDayAverageExcludesToday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        // An event happening today
        let todayNoon = now

        let events: [BabyEvent] = [
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: todayNoon, createdAt: todayNoon, createdBy: userID),
                amountMilliliters: 700,
                milkType: .formula
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        // Today's cumulative should see the 700 mL feed
        #expect(data.chartData.bottle.todayCumulative[12] == 700)
        // Average should NOT include today's event — it covers the prior 7 days only, which have no data
        #expect(data.chartData.bottle.averageCumulative[12] == 0)
    }

    @Test
    func bottleChartFilterSeriesTrackMilkTypeAndMixedInclusiveModes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 14)))
        let nineAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9)))
        let tenAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10)))
        let elevenAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 11)))

        let events: [BabyEvent] = [
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: nineAm, createdAt: nineAm, createdBy: userID),
                amountMilliliters: 100,
                milkType: .formula
            )),
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: tenAm, createdAt: tenAm, createdBy: userID),
                amountMilliliters: 80,
                milkType: .mixed
            )),
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: elevenAm, createdAt: elevenAm, createdBy: userID),
                amountMilliliters: 90,
                milkType: .breastMilk
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        #expect(data.chartData.bottleFormula.todayCumulative[11] == 100)
        #expect(data.chartData.bottleMixed.todayCumulative[11] == 80)
        #expect(data.chartData.bottleBreastMilk.todayCumulative[11] == 90)
        #expect(data.chartData.bottleFormulaIncludingMixed.todayCumulative[11] == 180)
        #expect(data.chartData.bottleBreastMilkIncludingMixed.todayCumulative[11] == 170)
    }

    @Test
    func nappyChartFilterSeriesTrackPeePooAndMixedInclusiveModes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 14)))
        let nineAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9)))
        let tenAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10)))
        let elevenAm = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 11)))

        let events: [BabyEvent] = [
            .nappy(try NappyEvent(
                metadata: EventMetadata(childID: childID, occurredAt: nineAm, createdAt: nineAm, createdBy: userID),
                type: .wee
            )),
            .nappy(try NappyEvent(
                metadata: EventMetadata(childID: childID, occurredAt: tenAm, createdAt: tenAm, createdBy: userID),
                type: .mixed,
                peeVolume: .medium,
                pooVolume: .light,
                pooColor: .yellow
            )),
            .nappy(try NappyEvent(
                metadata: EventMetadata(childID: childID, occurredAt: elevenAm, createdAt: elevenAm, createdBy: userID),
                type: .poo,
                pooVolume: .heavy,
                pooColor: .brown
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        #expect(data.chartData.nappyPee.todayCumulative[11] == 1)
        #expect(data.chartData.nappyMixed.todayCumulative[11] == 1)
        #expect(data.chartData.nappyPoo.todayCumulative[11] == 1)
        #expect(data.chartData.nappyPeeIncludingMixed.todayCumulative[11] == 2)
        #expect(data.chartData.nappyPooIncludingMixed.todayCumulative[11] == 2)
    }

    @Test
    func dryNappyCountIsIncludedSeparately() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        let nappyTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9)))

        let events: [BabyEvent] = [
            .nappy(try NappyEvent(
                metadata: EventMetadata(childID: childID, occurredAt: nappyTime, createdAt: nappyTime, createdBy: userID),
                type: .dry
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        #expect(data.dryNappyCount == 1)
        #expect(data.totalNappies == 1)
        #expect(data.wetNappyCount == 0)
        #expect(data.dirtyNappyCount == 0)
        #expect(data.mixedNappyCount == 0)
    }

    @Test
    func sleepExtrasAreNilWithNoSleepEvents() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        let data = TodaySummaryCalculator.makeData(from: [], now: now, calendar: calendar)

        #expect(data.shortestSleepBlockMinutes == nil)
        #expect(data.averageSleepBlockMinutes == nil)
        #expect(data.minutesSinceLastSleep == nil)
    }

    @Test
    func minutesSinceLastSleepIsIndependentOfLastFeed() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 15)))
        // Sleep ended at 10am
        let sleepEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10)))
        let sleepStart = sleepEnd.addingTimeInterval(-3_600)
        // Feed at 12pm (more recent than sleep)
        let feedTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: sleepEnd, createdAt: sleepEnd, createdBy: userID),
                startedAt: sleepStart,
                endedAt: sleepEnd
            )),
            .bottleFeed(try BottleFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: feedTime, createdAt: feedTime, createdBy: userID),
                amountMilliliters: 120,
                milkType: .formula
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        // Sleep ended at 10am, now is 3pm → 300 minutes since last sleep
        #expect(data.minutesSinceLastSleep == 300)
        // Feed at 12pm, now is 3pm → 180 minutes since last feed
        #expect(data.minutesSinceLastFeed == 180)
        // They must differ
        #expect(data.minutesSinceLastSleep != data.minutesSinceLastFeed)
    }

    @Test
    func shortestAndAverageSleepReflectMultipleSessions() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 20)))
        // 30-minute nap
        let nap1End = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10)))
        let nap1Start = nap1End.addingTimeInterval(-1_800)
        // 90-minute nap
        let nap2End = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 14)))
        let nap2Start = nap2End.addingTimeInterval(-5_400)

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: nap1End, createdAt: nap1End, createdBy: userID),
                startedAt: nap1Start,
                endedAt: nap1End
            )),
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: nap2End, createdAt: nap2End, createdBy: userID),
                startedAt: nap2Start,
                endedAt: nap2End
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        #expect(data.shortestSleepBlockMinutes == 30)
        #expect(data.longestSleepBlockMinutes == 90)
        #expect(data.averageSleepBlockMinutes == 60)
    }

    // MARK: - Active sleep tests

    @Test
    func activeSleepIsIncludedInTotalSleepMinutes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10)))
        // Baby fell asleep at 8am and is still sleeping (active session)
        let sleepStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 8)))

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: sleepStart, createdAt: sleepStart, createdBy: userID),
                startedAt: sleepStart,
                endedAt: nil
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        // 2 hours of active sleep should count
        #expect(data.totalSleepMinutes == 120)
        // While sleeping, minutesSinceLastSleep should be nil
        #expect(data.minutesSinceLastSleep == nil)
    }

    @Test
    func activeSleepThatStartedYesterdayIsIncludedInMetrics() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 2)))
        // Baby fell asleep at 10pm yesterday and is still sleeping
        let sleepStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 6, hour: 22)))

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: sleepStart, createdAt: sleepStart, createdBy: userID),
                startedAt: sleepStart,
                endedAt: nil
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)

        // 4 hours total (10pm→2am) should be in the total
        #expect(data.totalSleepMinutes == 240)
        #expect(data.minutesSinceLastSleep == nil)
    }

    @Test
    func sleepChartDistributesMinutesAcrossHours() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 15)))
        // 90-minute nap: 9:00am–10:30am
        let sleepStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9)))
        let sleepEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10, minute: 30)))

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: sleepEnd, createdAt: sleepEnd, createdBy: userID),
                startedAt: sleepStart,
                endedAt: sleepEnd
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)
        let today = data.chartData.sleep.todayCumulative

        // Hour 9 gets 60 minutes (9:00–10:00), hour 10 gets 30 minutes (10:00–10:30)
        // Cumulative: hour 9 = 60, hour 10 = 90, hour 11+ = 90
        #expect(today[8] == 0)
        #expect(today[9] == 60)
        #expect(today[10] == 90)
        #expect(today[14] == 90)
    }

    @Test
    func activeSleepIsIncludedInSleepChart() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 10, minute: 30)))
        // Baby fell asleep at 9am and is still sleeping
        let sleepStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 9)))

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: sleepStart, createdAt: sleepStart, createdBy: userID),
                startedAt: sleepStart,
                endedAt: nil
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)
        let today = data.chartData.sleep.todayCumulative

        // Hour 9: 60 min (9:00–10:00), hour 10: 30 min (10:00–10:30)
        // Cumulative: hour 9 = 60, hour 10 = 90
        #expect(today[9] == 60)
        #expect(today[10] == 90)
    }

    @Test
    func overnightActiveSleepAppearsInTodayChart() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 2)))
        // Baby fell asleep at 11pm yesterday
        let sleepStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 6, hour: 23)))

        let events: [BabyEvent] = [
            .sleep(try SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: sleepStart, createdAt: sleepStart, createdBy: userID),
                startedAt: sleepStart,
                endedAt: nil
            )),
        ]

        let data = TodaySummaryCalculator.makeData(from: events, now: now, calendar: calendar)
        let today = data.chartData.sleep.todayCumulative

        // Today's chart: midnight to 2am = 2 hours = 120 minutes
        // Hour 0 (midnight–1am): 60 min, hour 1 (1am–2am): 60 min
        #expect(today[0] == 60)
        #expect(today[1] == 120)
        // Hour 2 onwards: still 120 (nothing beyond now)
        #expect(today[2] == 120)
    }

    // MARK: - Existing tests

    @Test
    func makeDataSeparatesPureAndMixedNappyCounts() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        let wetTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 6)))
        let dirtyTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 7)))
        let mixedTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 8)))

        let events: [BabyEvent] = [
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: wetTime,
                        createdAt: wetTime,
                        createdBy: userID
                    ),
                    type: .wee,
                    peeVolume: .light
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: dirtyTime,
                        createdAt: dirtyTime,
                        createdBy: userID
                    ),
                    type: .poo,
                    pooVolume: .light,
                    pooColor: .yellow
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: mixedTime,
                        createdAt: mixedTime,
                        createdBy: userID
                    ),
                    type: .mixed,
                    peeVolume: .medium,
                    pooVolume: .medium,
                    pooColor: .brown
                )
            ),
        ]

        let data = TodaySummaryCalculator.makeData(
            from: events,
            now: now,
            calendar: calendar
        )

        #expect(data.totalNappies == 3)
        #expect(data.wetNappyCount == 1)
        #expect(data.dirtyNappyCount == 1)
        #expect(data.mixedNappyCount == 1)
    }
}
