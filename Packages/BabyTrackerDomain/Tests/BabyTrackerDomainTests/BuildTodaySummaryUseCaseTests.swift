import BabyTrackerDomain
import Foundation
import Testing

struct BuildTodaySummaryUseCaseTests {
    private let useCase = BuildTodaySummaryUseCase()

    @Test
    func executeIncludesBottleAndBreastFeedMetrics() throws {
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

        let summary = useCase.execute(events: events, now: now, calendar: calendar)

        #expect(summary.bottleCount == 2)
        #expect(summary.bottleTotalMilliliters == 210)
        #expect(summary.formulaMilliliters == 120)
        #expect(summary.breastMilkMilliliters == 90)
        #expect(summary.mixedMilkMilliliters == 0)
        #expect(summary.breastFeedCount == 1)
        #expect(summary.breastFeedTotalMinutes == 20)
        #expect(summary.averageBreastFeedMinutes == 20)
    }

    @Test
    func executeTracksNappyMixAndStreakAcrossDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 12)))
        let wetTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 6)))
        let dirtyTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 7)))
        let mixedTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 7, hour: 8)))
        let priorDayTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 6, hour: 18)))

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
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: priorDayTime,
                        createdAt: priorDayTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 60
                )
            ),
        ]

        let summary = useCase.execute(events: events, now: now, calendar: calendar)

        #expect(summary.totalNappies == 3)
        #expect(summary.wetNappyCount == 1)
        #expect(summary.dirtyNappyCount == 1)
        #expect(summary.mixedNappyCount == 1)
        #expect(summary.wetInclusiveCount == 2)
        #expect(summary.dirtyInclusiveCount == 2)
        #expect(summary.loggingStreakDays == 2)
    }
}
