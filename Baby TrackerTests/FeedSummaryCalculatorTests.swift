import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct FeedSummaryCalculatorTests {
    @Test
    func returnsLatestFeedAndTodaysCount() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let day = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 12))
        )
        let morningFeed = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 7, minute: 30))
        )
        let latestFeed = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 10, minute: 45))
        )
        let previousDayFeed = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 22))
        )

        let events: [BabyEvent] = [
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: morningFeed,
                        createdAt: morningFeed,
                        createdBy: userID
                    ),
                    side: .left,
                    startedAt: morningFeed.addingTimeInterval(-600),
                    endedAt: morningFeed
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: latestFeed,
                        createdAt: latestFeed,
                        createdBy: userID
                    ),
                    amountMilliliters: 120
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: previousDayFeed,
                        createdAt: previousDayFeed,
                        createdBy: userID
                    ),
                    amountMilliliters: 90,
                    milkType: .formula
                )
            ),
        ]

        let summary = try #require(
            FeedSummaryCalculator.makeSummary(
                from: events,
                on: day,
                calendar: calendar
            )
        )

        #expect(summary.lastFeedKind == .bottleFeed)
        #expect(summary.lastFeedTitle == "Bottle Feed")
        #expect(summary.lastFeedDetailText == "120 mL")
        #expect(summary.lastFeedAt == latestFeed)
        #expect(summary.feedsTodayCount == 2)
    }

    @Test
    func ignoresNewerNonFeedEventsWhenFindingLastFeed() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let day = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 12))
        )
        let feedTime = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 8, minute: 30))
        )
        let laterSleep = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 9))
        )

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: feedTime,
                        createdAt: feedTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 150,
                    milkType: .formula
                )
            ),
            .sleep(
                try SleepEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: laterSleep,
                        createdAt: laterSleep,
                        createdBy: userID
                    ),
                    startedAt: laterSleep.addingTimeInterval(-1_800),
                    endedAt: laterSleep
                )
            ),
        ]

        let summary = try #require(
            FeedSummaryCalculator.makeSummary(
                from: events,
                on: day,
                calendar: calendar
            )
        )

        #expect(summary.lastFeedKind == .bottleFeed)
        #expect(summary.lastFeedAt == feedTime)
        #expect(summary.feedsTodayCount == 1)
    }
}
