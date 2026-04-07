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
