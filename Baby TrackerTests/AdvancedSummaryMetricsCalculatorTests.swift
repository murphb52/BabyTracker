import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct AdvancedSummaryMetricsCalculatorTests {
    @Test
    func thirtyDayRangeBuildsThirtyDailyBuckets() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 18, hour: 10)))
        let viewState = AdvancedSummaryMetricsCalculator.makeViewState(
            from: [],
            selection: .range(.thirtyDays),
            now: now,
            calendar: calendar
        )

        #expect(viewState.dailyActivityCounts.count == 30)

        let firstDate = try #require(viewState.dailyActivityCounts.first?.date)
        let lastDate = try #require(viewState.dailyActivityCounts.last?.date)
        let expectedFirstDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 20)))
        let expectedLastDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 18)))

        #expect(firstDate == expectedFirstDate)
        #expect(lastDate == expectedLastDate)
    }

    @Test
    func daySelectionUsesOnlyTheChosenDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let selectedDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25, hour: 12)))
        let sameDayBottle = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25, hour: 8)))
        let sameDayNappy = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25, hour: 10)))
        let nextDayBottle = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 8)))

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: sameDayBottle,
                        createdAt: sameDayBottle,
                        createdBy: userID
                    ),
                    amountMilliliters: 120
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: sameDayNappy,
                        createdAt: sameDayNappy,
                        createdBy: userID
                    ),
                    type: .wee,
                    peeVolume: .medium
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: nextDayBottle,
                        createdAt: nextDayBottle,
                        createdBy: userID
                    ),
                    amountMilliliters: 180
                )
            ),
        ]

        let viewState = AdvancedSummaryMetricsCalculator.makeViewState(
            from: events,
            selection: AdvancedSummarySelection(mode: .day, range: .today, day: selectedDay),
            now: nextDayBottle,
            calendar: calendar
        )

        #expect(viewState.eventCount == 2)
        #expect(viewState.totalFeeds == 1)
        #expect(viewState.totalNappies == 1)
    }

    @Test
    func averageBottleVolumeUsesOnlyBottleFeedsInSelection() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 12)))
        let firstBottle = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 7)))
        let secondBottle = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 10)))

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: firstBottle,
                        createdAt: firstBottle,
                        createdBy: userID
                    ),
                    amountMilliliters: 120
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: secondBottle,
                        createdAt: secondBottle,
                        createdBy: userID
                    ),
                    amountMilliliters: 180
                )
            ),
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: secondBottle.addingTimeInterval(1_800),
                        createdAt: secondBottle.addingTimeInterval(1_800),
                        createdBy: userID
                    ),
                    side: .right,
                    startedAt: secondBottle.addingTimeInterval(900),
                    endedAt: secondBottle.addingTimeInterval(1_800)
                )
            ),
        ]

        let viewState = AdvancedSummaryMetricsCalculator.makeViewState(
            from: events,
            selection: .range(.today),
            now: now,
            calendar: calendar
        )

        #expect(viewState.bottleFeedCount == 2)
        #expect(viewState.averageBottleVolumeMilliliters == 150)
    }

    @Test
    func busiestHourUsesAllEventsInFilteredSelection() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 18)))
        let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 9)))
        let lateMorning = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 9, minute: 30)))
        let afternoon = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 15)))

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: morning,
                        createdAt: morning,
                        createdBy: userID
                    ),
                    amountMilliliters: 100
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: lateMorning,
                        createdAt: lateMorning,
                        createdBy: userID
                    ),
                    type: .mixed,
                    pooVolume: .light,
                    pooColor: .yellow
                )
            ),
            .sleep(
                try SleepEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: afternoon,
                        createdAt: afternoon,
                        createdBy: userID
                    ),
                    startedAt: afternoon.addingTimeInterval(-3_600),
                    endedAt: afternoon
                )
            ),
        ]

        let viewState = AdvancedSummaryMetricsCalculator.makeViewState(
            from: events,
            selection: .range(.today),
            now: now,
            calendar: calendar
        )

        #expect(viewState.busiestHourLabel == "9AM")
        #expect(viewState.busiestHourCount == 2)
    }
}
