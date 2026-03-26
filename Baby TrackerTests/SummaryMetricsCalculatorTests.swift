import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct SummaryMetricsCalculatorTests {
    @Test
    func snapshotIncludesTopLevelAndInDepthMetrics() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 12)))
        let firstFeedEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 7, minute: 30)))
        let secondFeedEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 10, minute: 0)))
        let sleepStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 1, minute: 0)))
        let sleepEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 2, minute: 30)))
        let wetNappyTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 9, minute: 15)))
        let dirtyNappyTime = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 11, minute: 15)))

        let events: [BabyEvent] = [
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: firstFeedEnd,
                        createdAt: firstFeedEnd,
                        createdBy: userID
                    ),
                    side: .left,
                    startedAt: firstFeedEnd.addingTimeInterval(-900),
                    endedAt: firstFeedEnd
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: secondFeedEnd,
                        createdAt: secondFeedEnd,
                        createdBy: userID
                    ),
                    amountMilliliters: 120
                )
            ),
            .sleep(
                try SleepEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: sleepEnd,
                        createdAt: sleepEnd,
                        createdBy: userID
                    ),
                    startedAt: sleepStart,
                    endedAt: sleepEnd
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: wetNappyTime,
                        createdAt: wetNappyTime,
                        createdBy: userID
                    ),
                    type: .wee,
                    peeVolume: .medium
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: dirtyNappyTime,
                        createdAt: dirtyNappyTime,
                        createdBy: userID
                    ),
                    type: .poo,
                    pooVolume: .light,
                    pooColor: .yellow
                )
            ),
        ]

        let snapshot = SummaryMetricsCalculator.makeSnapshot(
            from: events,
            range: .today,
            now: now,
            calendar: calendar
        )

        #expect(snapshot.eventCount == 5)
        #expect(snapshot.totalFeeds == 2)
        #expect(snapshot.totalNappies == 2)
        #expect(snapshot.totalSleepMinutes == 90)
        #expect(snapshot.averageFeedDurationMinutes == 15)
        #expect(snapshot.averageFeedIntervalMinutes == 150)
        #expect(snapshot.averageSleepBlockMinutes == 90)
        #expect(snapshot.shortestSleepBlockMinutes == 90)
        #expect(snapshot.longestSleepBlockMinutes == 90)
        #expect(snapshot.wetNappyCount == 1)
        #expect(snapshot.dirtyNappyCount == 1)
        #expect(snapshot.loggingStreakDays == 1)
        #expect(snapshot.dailyEventCounts.count == 7)
        #expect(snapshot.feedCountsByHour.count == 6)
    }

    @Test
    func snapshotUsesRangeFilterForRecentPeriods() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let childID = UUID()
        let userID = UUID()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 26, hour: 12)))
        let tenDaysAgo = try #require(calendar.date(byAdding: .day, value: -10, to: now))
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: now))

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: tenDaysAgo,
                        createdAt: tenDaysAgo,
                        createdBy: userID
                    ),
                    amountMilliliters: 110
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: yesterday,
                        createdAt: yesterday,
                        createdBy: userID
                    ),
                    amountMilliliters: 130
                )
            ),
        ]

        let sevenDaySnapshot = SummaryMetricsCalculator.makeSnapshot(
            from: events,
            range: .sevenDays,
            now: now,
            calendar: calendar
        )

        let allTimeSnapshot = SummaryMetricsCalculator.makeSnapshot(
            from: events,
            range: .allTime,
            now: now,
            calendar: calendar
        )

        #expect(sevenDaySnapshot.totalFeeds == 1)
        #expect(allTimeSnapshot.totalFeeds == 2)
    }
}
